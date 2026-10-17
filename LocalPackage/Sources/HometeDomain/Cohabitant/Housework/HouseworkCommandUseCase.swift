//
//  HouseworkCommandUseCase.swift
//  LocalPackage
//

import Foundation

/// 家事の完了・ありがとうの書き込みと、それに伴うAnalytics・同居人への通知
///
/// アプリの画面（`HouseworkListStore`）と、アプリを開かずに実行するApp Intentの両方から呼ぶ。
/// 最新の家事を探すのは呼び出し側の責務にする。Storeはリスナーで受け取った家事を、Intentはサーバーから取り直した家事を渡す
/// （[ADR-0044](doc/adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)）。
public struct HouseworkCommandUseCase: Sendable {

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let analyticsClient: AnalyticsClient
    private let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase
    private let calendar: Calendar

    public init(
        houseworkClient: HouseworkClient,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient,
        analyticsClient: AnalyticsClient,
        dailyCompletionReminderUseCase: DailyCompletionReminderUseCase,
        calendar: Calendar
    ) {
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.analyticsClient = analyticsClient
        self.dailyCompletionReminderUseCase = dailyCompletionReminderUseCase
        self.calendar = calendar
    }

    /// 家事を完了にする
    ///
    /// 同居人の端末でふりかえり通知を予約するため、今日の家事なら1日1回だけ完了通知を送る。
    /// コメントを添えたときは、入力したコメントが届かずに消えないよう、1日1回の制限に関係なく毎回送る。
    /// - Parameters:
    ///   - current: 完了にする家事。登録済みの家事なら、呼び出し側が見つけた最新の記録を渡す
    ///   - reporter: 完了にした人。通知の送り主になる
    ///   - executors: 担当者と、配分した割合・ポイント（`effort`で上乗せした後のポイントを配分したもの）
    ///   - effort: 頑張り度
    ///   - executorNames: 担当者の名前（`executors`と同じ順）。代わりに記録したときの通知の文言に使う
    ///   - comment: 完了通知に添えるコメント。空なら添えない
    ///   - notify: 一括操作では件数をまとめた1件の完了通知を呼び出し側で送るため`false`を渡す
    ///   - delivery: 通知の送信を待つかどうか
    ///   - onWritten: 書き込みがサーバーに届いたときに呼ぶ。通知を送り終えるのを待つときに、書き込みにかかった時間だけを測るため
    public func complete( // swiftlint:disable:this function_parameter_count function_body_length
        current: HouseworkItem,
        now: Date,
        reporter: Account,
        executors: [HouseworkExecutor],
        effort: HouseworkEffort,
        executorNames: [String],
        comment: String,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep,
        notify: Bool = true,
        delivery: HouseworkNotificationDelivery = .background,
        onWritten: @Sendable () -> Void = {}
    ) async throws {
        let executorType = HouseworkAnalyticsExecutorType(executors: executors, reporterId: reporter.id)
        let analyticsAction = { (isSuccess: Bool) -> HouseworkAnalyticsAction in
            .complete(step: step, executorType: executorType, effort: effort, isSuccess: isSuccess)
        }
        do {
            let completedItem = current.updateCompleted(at: now, executors: executors, effort: effort)
            // 登録されていない家事はドキュメントを新規作成する
            try await houseworkClient.insertOrUpdateItem(
                isRegistered ? completedItem : completedItem.updateCreatedAt(now),
                cohabitantId
            )
        } catch {
            analyticsClient.log(.housework(analyticsAction(false)))
            throw error
        }
        onWritten()
        analyticsClient.log(.housework(analyticsAction(true)))

        guard notify else { return }

        let reporterName = reporter.userName
        let houseworkTitle = current.title
        let content: @Sendable (HouseworkCompletedNotificationData?) -> PushNotificationContent = { data in
            switch executorType {
            case .ownOnly:
                .completedMessage(
                    executorName: reporterName,
                    houseworkTitle: houseworkTitle,
                    comment: comment,
                    data: data
                )

            case .others, .shared:
                .proxyCompletedMessage(
                    reporterName: reporterName,
                    executorNames: executorNames,
                    houseworkTitle: houseworkTitle,
                    comment: comment,
                    data: data
                )
            }
        }
        if comment.isEmpty {
            await notifyCompleted(
                houseworkDate: current.indexedDate.value,
                now: now,
                cohabitantId: cohabitantId,
                delivery: delivery,
                content: content
            )
        } else {
            await notifyCompletedWithComment(
                houseworkDate: current.indexedDate.value,
                now: now,
                cohabitantId: cohabitantId,
                delivery: delivery,
                content: content
            )
        }
    }

    /// 完了した家事に「ありがとう」を記録し、コメントが初めて付いたときだけ相手に通知する
    ///
    /// 1人が1つの家事に送れるありがとうは1件で、送信済みの家事に対して呼ぶとコメントの編集になる（最初に送った日時は変えない）。
    /// 通知はコメント付きで送ったときと、コメントなしで送った後に書き足したときだけ送る。
    /// 呼び出し元に返すのは記録の失敗だけで、通知の失敗は返さない。
    /// - Parameters:
    ///   - current: ありがとうを送る家事。呼び出し側が見つけた最新の記録を渡す
    ///   - comment: 添えるコメント。コメントなしで送る場合は`nil`
    ///   - delivery: 通知の送信を待つかどうか
    ///   - onWritten: 書き込みがサーバーに届いたときに呼ぶ。何も記録しないときは呼ばない
    /// - Returns: この家事に初めてありがとうを記録したかどうか。コメントの書き足し・編集だった場合や、
    ///   未完了に戻されていたなどで何も記録しなかった場合は`false`
    @discardableResult
    public func sendThanks( // swiftlint:disable:this function_parameter_count
        current: HouseworkItem,
        sender: Account,
        comment: String?,
        now: Date,
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        delivery: HouseworkNotificationDelivery = .background,
        onWritten: @Sendable () -> Void = {}
    ) async throws -> Bool {
        // 未完了へ戻された家事は、ありがとうを消す仕様なので記録しない
        guard current.state == .completed else { return false }
        let currentThanks = current.thanks[sender.id]
        // 画面の表示がリスナーに追いつく前の一括操作で、書いたコメントをコメントなしで消さないよう何もしない
        if comment == nil, currentThanks != nil { return false }
        let isEditing = currentThanks != nil
        let thanks = HouseworkThanks(comment: comment, sentAt: currentThanks?.sentAt ?? now)

        do {
            try await houseworkClient.upsertThanks(current.id, sender.id, thanks, cohabitantId)
        } catch {
            analyticsClient.log(.housework(thanksAnalyticsAction(isEditing: isEditing, step: step, isSuccess: false)))
            throw error
        }
        onWritten()
        analyticsClient.log(.housework(thanksAnalyticsAction(isEditing: isEditing, step: step, isSuccess: true)))

        if let comment, currentThanks?.comment == nil {
            let content = PushNotificationContent.thanksMessage(
                senderName: sender.userName,
                houseworkTitle: current.title,
                houseworkId: current.id,
                comment: comment
            )
            await deliver(delivery) {
                do {
                    try await cohabitantPushNotificationClient.send(cohabitantId, content)
                } catch {
                    print("failed to notify cohabitants of thanks: \(error)")
                }
            }
        }
        return !isEditing
    }

    /// 同居人の端末でふりかえり通知を予約するため、家事の完了を通知で知らせる
    ///
    /// 受け取った端末では、アプリが終了していてもNotification Service Extensionが起動して予約する。
    /// 送るのは今日の家事の完了で、かつこの端末からその日まだ送っていないときだけ（ベストエフォート）。
    /// 失敗しても家事の操作は失敗扱いにしない。
    /// - Parameter content: 送る通知の内容。予約に使う付加情報を受け取って組み立てる
    public func notifyCompleted(
        houseworkDate: Date,
        now: Date,
        cohabitantId: String,
        delivery: HouseworkNotificationDelivery = .background,
        content: @escaping @Sendable (HouseworkCompletedNotificationData) -> PushNotificationContent
    ) async {
        await deliver(delivery) {
            do {
                try await dailyCompletionReminderUseCase.notifyCompletedIfNeeded(
                    houseworkDate: houseworkDate,
                    now: now,
                    calendar: calendar
                ) { data in
                    try await cohabitantPushNotificationClient.send(cohabitantId, content(data))
                }
            } catch {
                print("failed to notify cohabitants of completed housework: \(error)")
            }
        }
    }

}

/// 同居人への通知を、送り終えるまで待つかどうか
public enum HouseworkNotificationDelivery: Sendable {

    /// 送信を待たずに返す。画面の操作では、通知の送信で操作の完了を遅らせないため
    case background
    /// 送り終えてから返す。App Intentでは、`perform`から返るとプロセスが止められて送れなくなりうるため
    case awaiting

}

private extension HouseworkCommandUseCase {

    func deliver(_ delivery: HouseworkNotificationDelivery, _ send: @escaping @Sendable () async -> Void) async {
        switch delivery {
        case .background:
            Task.detached {
                await send()
            }

        case .awaiting:
            await send()
        }
    }

    /// コメントを添えた完了通知を、1日1回の制限に関係なく送る
    ///
    /// ふりかえり通知の予約用データは、`notifyCompleted`と同じ条件のときだけ付ける。
    func notifyCompletedWithComment(
        houseworkDate: Date,
        now: Date,
        cohabitantId: String,
        delivery: HouseworkNotificationDelivery,
        content: @escaping @Sendable (HouseworkCompletedNotificationData?) -> PushNotificationContent
    ) async {
        await deliver(delivery) {
            do {
                try await dailyCompletionReminderUseCase.notifyCompletedWithComment(
                    houseworkDate: houseworkDate,
                    now: now,
                    calendar: calendar
                ) { data in
                    try await cohabitantPushNotificationClient.send(cohabitantId, content(data))
                }
            } catch {
                print("failed to notify cohabitants of completed housework with comment: \(error)")
            }
        }
    }

    func thanksAnalyticsAction(
        isEditing: Bool,
        step: HouseworkAnalyticsStep,
        isSuccess: Bool
    ) -> HouseworkAnalyticsAction {
        isEditing
            ? .editThanks(step: step, isSuccess: isSuccess)
            : .sendThanks(step: step, isSuccess: isSuccess)
    }

}
