//
//  HouseworkListStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/27.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class HouseworkListStore {

    public private(set) var items: StoredAllHouseworkList
    /// 家事のスナップショットリスナーの購読状態
    public private(set) var loadState: ListenerLoadState = .loading
    private let calendar: Calendar
    private let now: @MainActor @Sendable () -> Date
    private let idGenerator: @MainActor @Sendable () -> String
    /// 最後にふりかえり通知へ反映した「日付と、その日に完了した家事の件数」
    /// - Note: スナップショットは家事が1件変わるたびに届くため、結果が変わったときだけ予約し直す。
    ///         件数で見るのは、1日1回の制限を外している間（デバッグ用）に完了のたびに予約を積むため
    private var lastReminderSyncState: DailyCompletionReminderSyncState?

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let houseworkManager: HouseworkManager
    private let analyticsClient: AnalyticsClient
    private let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase

    private let houseworkListObserveKey = "houseworkListObserveKey"

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        analyticsClient: AnalyticsClient = .previewValue,
        dailyCompletionReminderUseCase: DailyCompletionReminderUseCase = .init(client: .previewValue),
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping @MainActor @Sendable () -> Date = { .now },
        items: [DailyHouseworkList] = [],
        idGenerator: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.analyticsClient = analyticsClient
        self.dailyCompletionReminderUseCase = dailyCompletionReminderUseCase
        self.calendar = calendar
        self.now = now
        self.idGenerator = idGenerator
        self.items = .init(value: items)

        Task {
            await startObserving()
        }
    }

    /// 家事をまとめて登録する
    /// - Note: 一括書き込みのため、全件成功か全件失敗かのどちらかになる。
    ///         登録を同居人へは通知しない。家事のステータスに関わる通知は、ふりかえり通知だけにしている。
    ///         Analyticsは既存の指標の意味を保つため、家事1件につき1イベント送る
    /// - Parameter memoLimitPolicy: 入力したメモの上限の判定に使う、操作している本人のプラン
    /// - Throws: 入力したメモが上限を超えている場合は`HouseworkMemoError.limitExceeded`（1件も書き込まない）
    public func register(
        newItems: [NewHouseworkEntry],
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        memoLimitPolicy: HouseworkMemoLimitPolicy
    ) async throws {
        guard !newItems.isEmpty else { return }
        do {
            for entry in newItems {
                try entry.validateMemo(limitPolicy: memoLimitPolicy)
            }
            // まとめて登録した家事は同時に作られたものとして扱い、作成日時を揃える
            let createdAt = now()
            try await houseworkClient.insertOrUpdateItems(
                newItems.map { $0.item.updateCreatedAt(createdAt) },
                cohabitantId
            )
        } catch {
            logRegistered(newItems, step: step, isSuccess: false)
            throw error
        }
        logRegistered(newItems, step: step, isSuccess: true)
    }

    /// 家事を完了にする
    ///
    /// 同居人の端末でふりかえり通知を予約するため、今日の家事なら1日1回だけ完了通知を送る。
    /// コメントを添えたときは、入力したコメントが届かずに消えないよう、1日1回の制限に関係なく毎回送る。
    /// - Parameters:
    ///   - reporter: 完了にした人。通知の送り主になる
    ///   - executors: 担当者と、配分した割合・ポイント（`effort`で上乗せした後のポイントを配分したもの）
    ///   - effort: 頑張り度
    ///   - executorNames: 担当者の名前（`executors`と同じ順）。代わりに記録したときの通知の文言に使う
    ///   - comment: 完了通知に添えるコメント。空なら添えない
    ///   - notify: 一括操作では件数をまとめた1件の完了通知を呼び出し側で送るため`false`を渡す。
    // swiftlint:disable:next function_parameter_count
    public func complete(
        target: HouseworkItem,
        now: Date,
        reporter: Account,
        executors: [HouseworkExecutor],
        effort: HouseworkEffort,
        executorNames: [String],
        comment: String,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws {
        let executorType = HouseworkAnalyticsExecutorType(executors: executors, reporterId: reporter.id)
        let analyticsAction = { (isSuccess: Bool) -> HouseworkAnalyticsAction in
            .complete(step: step, executorType: executorType, effort: effort, isSuccess: isSuccess)
        }
        do {
            if isRegistered {
                // Houseworksコレクションに登録されている家事の場合はステータスを更新する
                try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                    $0.updateCompleted(at: now, executors: executors, effort: effort)
                }
            } else {
                // 登録されていない場合はドキュメントを新規作成する
                let updatedItem = target
                    .updateCompleted(at: now, executors: executors, effort: effort)
                    .updateCreatedAt(now)
                try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
            }
        } catch {
            analyticsClient.log(.housework(analyticsAction(false)))
            throw error
        }
        analyticsClient.log(.housework(analyticsAction(true)))

        guard notify else { return }

        let reporterName = reporter.userName
        let houseworkTitle = target.title
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
            notifyCompleted(
                houseworkDate: target.indexedDate.value,
                now: now,
                cohabitantId: cohabitantId,
                content: content
            )
        } else {
            notifyCompletedWithComment(
                houseworkDate: target.indexedDate.value,
                now: now,
                cohabitantId: cohabitantId,
                content: content
            )
        }
    }

    /// 完了した家事を、もう一度やったものとして記録する
    ///
    /// 元の家事は変えずに、同じ日・同じ内容の完了済みの家事を新しく登録する。
    /// 同居人への通知は家事を完了にしたときと同じく、今日の家事なら1日1回だけ完了通知を送る。
    public func redo(
        target: HouseworkItem,
        now: Date,
        executor: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            let redoneItem = target.makeRedone(id: idGenerator(), at: now, executor: executor.id)
            try await houseworkClient.insertOrUpdateItem(redoneItem, cohabitantId)
        } catch {
            analyticsClient.log(.housework(.redo(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.redo(step: step, isSuccess: true)))

        notifyCompleted(houseworkDate: target.indexedDate.value, now: now, cohabitantId: cohabitantId) {
            .completedMessage(executorName: executor.userName, houseworkTitle: target.title, comment: "", data: $0)
        }
    }

    /// 完了した家事に手伝った人を足す
    ///
    /// 家事の合計ポイントは変えず、担当者とポイントの配分だけを入れ替える。完了日時・頑張り度・
    /// ありがとうは変えない。同居人への通知は送らない（家事のステータスに関わる通知はふりかえり通知だけ）。
    /// - Parameter executors: 入れ替える担当者。ポイントの合計は入れ替える前の`earnedPoint`と一致させる
    public func addHelpers(
        target: HouseworkItem,
        executors: [HouseworkExecutor],
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        // 手元の家事は画面を開いた時点のものなので、リスナーで受け取った最新の記録を見て判断する。
        // 書き込みにも同じ記録を使い、判断と書き込みの間に一覧が入れ替わっても食い違わないようにする
        let current = items.item(target) ?? target
        // 画面を開いている間に未完了へ戻された家事は担当者を持たない仕様なので、何もしない
        guard current.state == .completed else { return }
        // 配分は画面を開いた時点の合計ポイントで組み立てているため、その間に同居人が完了をやり直して
        // 合計が変わっていたら書き込まない。合わない配分で上書きすると家事の合計ポイントが増減する
        guard executors.reduce(0) { $0 + $1.point } == current.earnedPoint else { return }

        do {
            try await houseworkClient.insertOrUpdateItem(current.updateExecutors(executors), cohabitantId)
        } catch {
            analyticsClient.log(.housework(.addHelper(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.addHelper(step: step, isSuccess: true)))
    }

    /// 完了した家事に「ありがとう」を記録し、コメントが初めて付いたときだけ相手に通知する
    ///
    /// 1人が1つの家事に送れるありがとうは1件で、送信済みの家事に対して呼ぶとコメントの編集になる（最初に送った日時は変えない）。
    /// 通知はコメント付きで送ったときと、コメントなしで送った後に書き足したときだけ送る。
    /// 呼び出し元に返すのは記録の失敗だけで、通知の送信は待たない。
    /// - Parameter comment: 添えるコメント。コメントなしで送る場合は`nil`
    /// - Returns: この家事に初めてありがとうを記録したかどうか。コメントの書き足し・編集だった場合や、
    ///   未完了に戻されていたなどで何も記録しなかった場合は`false`
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    public func sendThanks(
        target: HouseworkItem,
        sender: Account,
        comment: String?,
        now: Date,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> Bool {
        // 手元の家事は画面を開いた時点のものなので、リスナーで受け取った最新の記録を見て判断する
        let current = items.item(target) ?? target
        // 画面を開いている間に未完了へ戻された家事は、ありがとうを消す仕様なので記録しない
        guard current.state == .completed else { return false }
        let currentThanks = current.thanks[sender.id]
        // 画面の表示がリスナーに追いつく前の一括操作で、書いたコメントをコメントなしで消さないよう何もしない
        if comment == nil, currentThanks != nil { return false }
        let isEditing = currentThanks != nil
        let thanks = HouseworkThanks(comment: comment, sentAt: currentThanks?.sentAt ?? now)

        do {
            try await houseworkClient.upsertThanks(target.id, sender.id, thanks, cohabitantId)
        } catch {
            analyticsClient.log(.housework(thanksAnalyticsAction(isEditing: isEditing, step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(thanksAnalyticsAction(isEditing: isEditing, step: step, isSuccess: true)))

        if let comment, currentThanks?.comment == nil {
            notifyThanks(
                cohabitantId: cohabitantId,
                content: .thanksMessage(
                    senderName: sender.userName,
                    houseworkTitle: target.title,
                    houseworkId: target.id,
                    comment: comment
                )
            )
        }
        return !isEditing
    }

    public func returnToIncomplete(
        target: HouseworkItem,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                $0.updateIncomplete()
            }
        } catch {
            analyticsClient.log(.housework(.returnIncomplete(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.returnIncomplete(step: step, isSuccess: true)))
    }

    public func remove(
        target: HouseworkItem,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            if isRegistered {
                try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                    $0.updateNotTodo()
                }
            } else {
                let updatedItem = target.updateNotTodo().updateCreatedAt(now())
                try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
            }
        } catch {
            analyticsClient.log(.housework(.delete(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.delete(step: step, isSuccess: true)))
    }

    /// 家事のメモ（テキスト・チェックリストの項目）を保存する
    ///
    /// メモの追加・更新は同居人に通知しない。
    /// - Parameter limitPolicy: 上限の判定に使う、操作している本人のプラン
    /// - Throws: 画面を開いている間に同居人が完了・「やらない」にして、メモを編集できなくなっていた場合は
    ///           `HouseworkMemoError.notEditable`。上限を超えている場合は`HouseworkMemoError.limitExceeded`
    public func updateMemo(
        target: HouseworkItem,
        memo: HouseworkMemo,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep,
        limitPolicy: HouseworkMemoLimitPolicy
    ) async throws {
        do {
            try await saveMemo(
                target: target,
                cohabitantId: cohabitantId,
                isRegistered: isRegistered,
                limitPolicy: limitPolicy
            ) { current in
                memo.mergingCheckState(from: current.memo)
            }
        } catch {
            analyticsClient.log(.housework(.editMemo(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.editMemo(step: step, isSuccess: true)))
    }

    /// メモのチェックリストの項目のチェックを切り替えて保存する
    ///
    /// 同居人が同時に別の項目をチェックしたときに消しにくくするため、リスナーで受け取った最新のメモに対して切り替える。
    /// 読んでから書くまでの間に同居人が書いた分は上書きしうる。
    /// - Throws: メモを編集できなくなっていた場合は`HouseworkMemoError.notEditable`
    public func toggleMemoChecklistItem(
        target: HouseworkItem,
        itemId: HouseworkMemoChecklistItem.ID,
        cohabitantId: String,
        isRegistered: Bool,
        limitPolicy: HouseworkMemoLimitPolicy
    ) async throws {
        try await saveMemo(
            target: target,
            cohabitantId: cohabitantId,
            isRegistered: isRegistered,
            limitPolicy: limitPolicy
        ) { current in
            (current.memo ?? .empty).toggled(itemId)
        }
    }

    /// 同居人の端末でふりかえり通知を予約するため、家事の完了を通知で知らせる
    ///
    /// 受け取った端末では、アプリが終了していてもNotification Service Extensionが起動して予約する。
    /// 送るのは今日の家事の完了で、かつこの端末からその日まだ送っていないときだけ（ベストエフォート）。
    /// 送信は待たずに行い、失敗しても家事の操作は失敗扱いにしない。
    /// - Parameter content: 送る通知の内容。予約に使う付加情報を受け取って組み立てる
    public func notifyCompleted(
        houseworkDate: Date,
        now: Date,
        cohabitantId: String,
        content: @escaping @Sendable (HouseworkCompletedNotificationData) -> PushNotificationContent
    ) {
        let calendar = calendar
        Task.detached {
            do {
                try await self.dailyCompletionReminderUseCase.notifyCompletedIfNeeded(
                    houseworkDate: houseworkDate,
                    now: now,
                    calendar: calendar
                ) { data in
                    try await self.cohabitantPushNotificationClient.send(cohabitantId, content(data))
                }
            } catch {
                print("failed to notify cohabitants of completed housework: \(error)")
            }
        }
    }

}

private extension HouseworkListStore {

    func logRegistered(_ entries: [NewHouseworkEntry], step: HouseworkAnalyticsStep, isSuccess: Bool) {
        for entry in entries {
            analyticsClient.log(.housework(.register(step: step, source: entry.source, isSuccess: isSuccess)))
        }
    }

    func startObserving() async {
        let stream = await houseworkManager.createObserver(houseworkListObserveKey)
        for await result in stream {
            switch result {
            case let .success(newItems):
                let anchorDate = await houseworkManager.listenerAnchorDate
                items = StoredAllHouseworkList.makeMultiDateList(
                    items: newItems,
                    anchorDate: anchorDate,
                    offsetDays: HouseworkManager.listenerOffset,
                    calendar: calendar
                )
                print("did receive current items: \(items)")
                loadState = .loaded
                await syncDailyCompletionReminder()

            case let .failure(error):
                print("error occurred at housework snapshot listener: \(error)")
                loadState = .failed(error)
            }
        }
    }

    /// メモを保存する。登録済みの家事はメモのフィールドだけを、未登録の家事はドキュメントごと書く
    /// - Parameter makeMemo: 最新の家事から、保存するメモを作る
    func saveMemo(
        target: HouseworkItem,
        cohabitantId: String,
        isRegistered: Bool,
        limitPolicy: HouseworkMemoLimitPolicy,
        makeMemo: (HouseworkItem) -> HouseworkMemo
    ) async throws {
        // 手元の家事は画面を開いた時点のものなので、リスナーで受け取った最新の状態を見て判断する
        let current = isRegistered ? items.item(target) ?? target : target
        // 編集できるか・上限を超えていないかは家事が判定する
        let updatedItem = try current.updateMemo(makeMemo(current), limitPolicy: limitPolicy)
        if isRegistered {
            try await houseworkClient.updateMemo(target.id, updatedItem.memo ?? .empty, cohabitantId)
        } else {
            try await houseworkClient.insertOrUpdateItem(updatedItem.updateCreatedAt(now()), cohabitantId)
        }
    }

    /// 最新の家事に変更を当てて保存する
    ///
    /// 手元の家事は画面を開いた時点のものなので、リスナーで受け取った最新の記録に当てる。
    /// 一覧に見つからないとき（同居人が消した・保持期限で一覧から外れた・リスナーがまだ届いていない）は
    /// 手元の家事に当てる。操作のたびにクラッシュさせるよりは書き込みを試みる方がよく、`saveMemo`と同じ方針。
    func updateAndSave(
        target: HouseworkItem,
        cohabitantId: String,
        transform: (HouseworkItem) -> HouseworkItem
    ) async throws {
        let updatedItem = transform(items.item(target) ?? target)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
    }

    /// 今日完了した家事があるかを、ふりかえり通知の予約に反映する
    func syncDailyCompletionReminder() async {
        let currentDate = now()
        let completedCount = items.value
            .filter { calendar.isDate($0.metaData.indexedDate.value, inSameDayAs: currentDate) }
            .flatMap(\.items)
            .count { $0.state == .completed }
        let syncState = DailyCompletionReminderSyncState(
            day: calendar.startOfDay(for: currentDate),
            completedCount: completedCount
        )
        guard syncState != lastReminderSyncState else { return }

        lastReminderSyncState = syncState
        await dailyCompletionReminderUseCase.syncToday(
            hasCompletedHousework: completedCount > .zero,
            now: currentDate,
            calendar: calendar
        )
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

    /// ありがとうに添えたコメントを同居人へ知らせる
    ///
    /// 送信は待たずに行い、失敗しても記録は失敗扱いにしない。
    /// 送り直しても編集扱いになって通知は送られないが、ありがとう自体は記録できているため。
    func notifyThanks(cohabitantId: String, content: PushNotificationContent) {
        Task.detached {
            do {
                try await self.cohabitantPushNotificationClient.send(cohabitantId, content)
            } catch {
                print("failed to notify cohabitants of thanks: \(error)")
            }
        }
    }

    /// コメントを添えた完了通知を、1日1回の制限に関係なく送る
    ///
    /// ふりかえり通知の予約用データは、`notifyCompleted`と同じ条件のときだけ付ける。
    /// 送信は待たずに行い、失敗しても家事の操作は失敗扱いにしない。
    func notifyCompletedWithComment(
        houseworkDate: Date,
        now: Date,
        cohabitantId: String,
        content: @escaping @Sendable (HouseworkCompletedNotificationData?) -> PushNotificationContent
    ) {
        let calendar = calendar
        Task.detached {
            do {
                try await self.dailyCompletionReminderUseCase.notifyCompletedWithComment(
                    houseworkDate: houseworkDate,
                    now: now,
                    calendar: calendar
                ) { data in
                    try await self.cohabitantPushNotificationClient.send(cohabitantId, content(data))
                }
            } catch {
                print("failed to notify cohabitants of completed housework with comment: \(error)")
            }
        }
    }

}

/// ふりかえり通知へ最後に反映した内容
private struct DailyCompletionReminderSyncState: Equatable {

    let day: Date
    let completedCount: Int

}
