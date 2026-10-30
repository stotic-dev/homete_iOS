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
    /// 最後にOSへ読み直してもらった「日付と、その日の家事の名前ごとの状態」
    /// - Note: 曜日でテンプレートの家事が変わるため、名前が同じでも日付が変わったら読み直してもらう
    private var lastHouseworkTitlesState: HouseworkTitlesState?

    private let houseworkClient: HouseworkClient
    private let houseworkManager: HouseworkManager
    private let analyticsClient: AnalyticsClient
    private let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase
    private let commandUseCase: HouseworkCommandUseCase
    private let intentDonationClient: IntentDonationClient

    private let houseworkListObserveKey = "houseworkListObserveKey"

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        analyticsClient: AnalyticsClient = .previewValue,
        dailyCompletionReminderUseCase: DailyCompletionReminderUseCase = .init(client: .previewValue),
        intentDonationClient: IntentDonationClient = .previewValue,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping @MainActor @Sendable () -> Date = { .now },
        items: [DailyHouseworkList] = [],
        idGenerator: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {
        self.houseworkClient = houseworkClient
        self.houseworkManager = houseworkManager
        self.analyticsClient = analyticsClient
        self.dailyCompletionReminderUseCase = dailyCompletionReminderUseCase
        self.intentDonationClient = intentDonationClient
        self.calendar = calendar
        self.now = now
        self.idGenerator = idGenerator
        self.items = .init(value: items)
        commandUseCase = .init(
            houseworkClient: houseworkClient,
            cohabitantPushNotificationClient: cohabitantPushNotificationClient,
            analyticsClient: analyticsClient,
            dailyCompletionReminderUseCase: dailyCompletionReminderUseCase,
            calendar: calendar
        )

        Task {
            await startObserving()
        }
    }

    /// 家事をまとめて登録する
    ///
    /// 書き込み・Analyticsの詳細は`HouseworkCommandUseCase.register`を参照。
    /// - Parameter memoLimitPolicy: 入力したメモの上限の判定に使う、操作している本人のプラン
    /// - Throws: 入力したメモが上限を超えている場合は`HouseworkMemoError.limitExceeded`（1件も書き込まない）
    public func register(
        newItems: [NewHouseworkEntry],
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        memoLimitPolicy: HouseworkMemoLimitPolicy
    ) async throws {
        try await commandUseCase.register(
            newItems: newItems,
            createdAt: now(),
            cohabitantId: cohabitantId,
            step: step,
            memoLimitPolicy: memoLimitPolicy
        )
    }

    /// 家事を完了にする
    ///
    /// 書き込み・Analytics・通知の詳細は`HouseworkCommandUseCase.complete`を参照。
    /// 手元の家事は画面を開いた時点のものなので、登録済みの家事はリスナーで受け取った最新の記録に当てる。
    /// 1件だけ完了にしたときは、同じ家事をSiriやロック画面で提案してもらえるようドネーションする。
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
        try await commandUseCase.complete(
            current: isRegistered ? items.item(target) ?? target : target,
            now: now,
            reporter: reporter,
            executors: executors,
            effort: effort,
            executorNames: executorNames,
            comment: comment,
            cohabitantId: cohabitantId,
            isRegistered: isRegistered,
            step: step,
            notify: notify
        )
        if notify {
            intentDonationClient.donateCompleteHousework(target.title)
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
    /// 判定と書き込みの詳細は`HouseworkCommandUseCase.sendThanks`を参照。
    /// 手元の家事は画面を開いた時点のものなので、リスナーで受け取った最新の記録を見て判断する。
    /// 初めてありがとうを記録したときは、Siriやロック画面で提案してもらえるようドネーションする（コメントの編集ではしない）。
    /// - Parameter comment: 添えるコメント。コメントなしで送る場合は`nil`
    /// - Returns: この家事に初めてありがとうを記録したかどうか
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
        let isFirstThanks = try await commandUseCase.sendThanks(
            current: items.item(target) ?? target,
            sender: sender,
            comment: comment,
            now: now,
            cohabitantId: cohabitantId,
            step: step
        )
        if isFirstThanks {
            intentDonationClient.donateSendThanks()
        }
        return isFirstThanks
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
    /// 送信は待たずに行う。条件は`HouseworkCommandUseCase.notifyCompleted`を参照。
    /// - Parameter content: 送る通知の内容。予約に使う付加情報を受け取って組み立てる
    public func notifyCompleted(
        houseworkDate: Date,
        now: Date,
        cohabitantId: String,
        content: @escaping @Sendable (HouseworkCompletedNotificationData) -> PushNotificationContent
    ) {
        let commandUseCase = commandUseCase
        Task.detached {
            await commandUseCase.notifyCompleted(
                houseworkDate: houseworkDate,
                now: now,
                cohabitantId: cohabitantId,
                delivery: .awaiting,
                content: content
            )
        }
    }

}

// MARK: - 別の日へまわす

// `idGenerator`・`now`・`calendar`を使うため、クラスと同じファイルに置く
public extension HouseworkListStore {

    /// 未完了の家事を別の日へまわす
    ///
    /// 書き込む家事の決め方は`HouseworkPostponePlan`を参照。元の日の記録とまわす先の家事は1回の`WriteBatch`で書き込む。
    /// 同居人への通知は送らない（家事のステータスに関わる通知はふりかえり通知だけ）。
    /// 手元の家事は画面を開いた時点のものなので、登録済みの家事はリスナーで受け取った最新の記録で判断する。
    /// - Parameters:
    ///   - templateContext: まわす先の日にテンプレートから出る家事を探すのに使う
    ///   - storagePolicy: まわす先の日付から保持期限を求めるのに使う
    /// - Returns: まわした結果。画面を開いている間に同居人が完了・「やらない」にしていて、まわさなかったときは`nil`
    @discardableResult
    func postpone( // swiftlint:disable:this function_parameter_count
        target: HouseworkItem,
        isRegistered: Bool,
        to destination: Date,
        templateContext: HouseworkTemplateContext,
        storagePolicy: HouseworkStoragePolicy,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> HouseworkPostponePlan.Outcome? {
        let current = isRegistered ? items.item(target) ?? target : target
        guard current.state == .incomplete,
              isRegistered || !hasRegisteredTemplateRecord(of: target) else { return nil }

        let plan = postponePlan(
            target: current,
            isRegistered: isRegistered,
            to: destination,
            templateContext: templateContext,
            storagePolicy: storagePolicy
        )
        do {
            try await houseworkClient.insertOrUpdateItems(plan.writes, cohabitantId)
        } catch {
            analyticsClient.log(.housework(.postpone(step: step, outcome: plan.outcome, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.postpone(step: step, outcome: plan.outcome, isSuccess: true)))
        return plan.outcome
    }

    /// テンプレートから出している家事と同じテンプレートの記録が、その日にすでに登録されているか
    ///
    /// 画面を開いている間に同居人が完了・「やらない」にすると、テンプレートの家事は別のIDで登録される。
    /// そのまま元の日の記録を書くと、同じテンプレートの記録が2件になるため、まわさずに返す判定に使う。
    private func hasRegisteredTemplateRecord(of target: HouseworkItem) -> Bool {
        guard let templateItemId = target.templateHouseworkItemId else { return false }

        return items.value
            .first { $0.metaData.indexedDate == target.indexedDate }?
            .items
            .contains { $0.templateHouseworkItemId == templateItemId } ?? false
    }

    /// 家事を別の日へまわしたときに書き込む家事と結果を、書き込まずに返す
    ///
    /// まわす先に同じ名前の家事があるかを、書き込む前に確かめるのに使う。
    func postponePlan(
        target: HouseworkItem,
        isRegistered: Bool,
        to destination: Date,
        templateContext: HouseworkTemplateContext,
        storagePolicy: HouseworkStoragePolicy
    ) -> HouseworkPostponePlan {
        .make(
            target: target,
            isRegistered: isRegistered,
            destination: destination,
            storedItems: items,
            templateContext: templateContext,
            now: now(),
            calendar: calendar,
            storagePolicy: storagePolicy,
            newItemId: idGenerator()
        )
    }

}

// MARK: - 複数選択の一括操作

/// 複数選択で選んだ家事への一括操作
///
/// 1回の`WriteBatch`でまとめて書き込み、全件成功か全件失敗のどちらかにする。1件ずつ書き込むと、途中で失敗したときに
/// 一部の家事にだけ反映されてしまうため。家事ごとの判定（未登録か・ありがとうを記録できるか）は書き込む前に
/// リスナーで受け取った最新の記録で全件分そろえ、判定した結果が0件なら書き込みもAnalyticsの送信もしない。
/// Analyticsは操作1回につき1イベントだけ送り、書き込んだ件数を`item_count`に載せる。
public extension HouseworkListStore {

    /// 家事をまとめて完了にする
    ///
    /// 頑張り度や担当者を選ぶ画面を通らないため、自分だけを担当者にして「ふつう」で記録し、上乗せ前のポイントを満額配分する。
    /// 家事ごとの個別の通知は送らず、件数をまとめた1件の完了通知を今日の家事で1日1回だけ送る。
    func completeBulk(
        targets: [HouseworkItem],
        now: Date,
        reporter: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        let updatedItems = bulkUpdatedItems(targets, now: now) {
            $0.updateCompleted(
                at: now,
                executors: [.solo(userId: reporter.id, point: $0.point)],
                effort: .normal
            )
        }
        guard let firstItem = updatedItems.first else { return }

        try await saveBulk(updatedItems, cohabitantId: cohabitantId) {
            .complete(step: step, executorType: .ownOnly, effort: .normal, isSuccess: $0)
        }

        // 複数選択は1日分の家事ボード内で行うため、先頭の家事の日付を代表として使う
        notifyCompleted(houseworkDate: firstItem.indexedDate.value, now: now, cohabitantId: cohabitantId) {
            .completedBulkMessage(executorName: reporter.userName, count: updatedItems.count, data: $0)
        }
    }

    /// 家事をまとめて「やらない」にする
    func removeBulk(
        targets: [HouseworkItem],
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        let updatedItems = bulkUpdatedItems(targets, now: now()) { $0.updateNotTodo() }
        guard !updatedItems.isEmpty else { return }

        try await saveBulk(updatedItems, cohabitantId: cohabitantId) {
            .delete(step: step, isSuccess: $0)
        }
    }

    /// 家事をまとめて未完了に戻す
    func returnToIncompleteBulk(
        targets: [HouseworkItem],
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        let updatedItems = bulkUpdatedItems(targets, now: now()) { $0.updateIncomplete() }
        guard !updatedItems.isEmpty else { return }

        try await saveBulk(updatedItems, cohabitantId: cohabitantId) {
            .returnIncomplete(step: step, isSuccess: $0)
        }
    }

    /// 家事にまとめて、コメントなしのありがとうを記録する
    ///
    /// 送信済みのありがとうは上書きしない（書いたコメントをコメントなしで消さないため）。未完了に戻された家事には記録しない。
    /// コメントがないので通知は送らない。
    /// - Returns: 1件でもありがとうを記録したかどうか。記録した家事はすべて初めてのありがとうになる
    @discardableResult
    func sendThanksBulk(
        targets: [HouseworkItem],
        sender: Account,
        now: Date,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> Bool {
        let houseworkIds = targets
            .filter {
                let current = items.item($0) ?? $0
                return current.state == .completed && current.thanks[sender.id] == nil
            }
            .map(\.id)
        guard !houseworkIds.isEmpty else { return false }

        let logEvent = { (isSuccess: Bool) in
            self.analyticsClient.log(
                .housework(.sendThanks(step: step, isSuccess: isSuccess), itemCount: houseworkIds.count)
            )
        }
        do {
            try await houseworkClient.upsertThanksBatch(
                houseworkIds,
                sender.id,
                HouseworkThanks(comment: nil, sentAt: now),
                cohabitantId
            )
        } catch {
            logEvent(false)
            throw error
        }
        logEvent(true)
        return true
    }

}

private extension HouseworkListStore {

    /// 一括操作で書き込む家事を、リスナーで受け取った最新の記録に変更を当てて作る
    ///
    /// 一覧に見つからない家事は、まだ登録されていない（テンプレートから出している）家事としてドキュメントを新規作成する。
    func bulkUpdatedItems(
        _ targets: [HouseworkItem],
        now: Date,
        transform: (HouseworkItem) -> HouseworkItem
    ) -> [HouseworkItem] {
        targets.map { target in
            guard let current = items.item(target) else {
                return transform(target).updateCreatedAt(now)
            }
            return transform(current)
        }
    }

    /// 一括操作の家事をまとめて書き込み、書き込んだ件数を付けてAnalyticsを1回だけ送る
    func saveBulk(
        _ updatedItems: [HouseworkItem],
        cohabitantId: String,
        analyticsAction: (Bool) -> HouseworkAnalyticsAction
    ) async throws {
        do {
            try await houseworkClient.insertOrUpdateItems(updatedItems, cohabitantId)
        } catch {
            analyticsClient.log(.housework(analyticsAction(false), itemCount: updatedItems.count))
            throw error
        }
        analyticsClient.log(.housework(analyticsAction(true), itemCount: updatedItems.count))
    }

    func startObserving() async {
        let stream = await houseworkManager.createObserver(houseworkListObserveKey)
        for await result in stream {
            switch result {
            case let .success(newItems):
                items = StoredAllHouseworkList.makeMultiDateList(items: newItems)
                print("did receive current items: \(items)")
                loadState = .loaded
                updateHouseworkTitlesIfNeeded()
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

    /// 今日の家事の名前か状態が変わったときだけ、Siriで言える家事の名前をOSに読み直してもらう
    ///
    /// Siriに出すのは未完了の家事の名前で、テンプレートから出している未登録の家事も含む。未登録の家事は
    /// 完了にすると初めて一覧に現れるため、未完了の名前だけでなく名前ごとの状態の変化を見る。
    /// 読み直すたびにIntentの候補をサーバーから取り直すため、スナップショットのたびには頼まない。
    func updateHouseworkTitlesIfNeeded() {
        let currentDate = now()
        let todayItems = items.value
            .filter { calendar.isDate($0.metaData.indexedDate.value, inSameDayAs: currentDate) }
            .flatMap(\.items)
        let state = HouseworkTitlesState(
            day: calendar.startOfDay(for: currentDate),
            statesByTitle: Dictionary(grouping: todayItems, by: \.title).mapValues { Set($0.map(\.state)) }
        )
        guard state != lastHouseworkTitlesState else { return }

        lastHouseworkTitlesState = state
        intentDonationClient.updateHouseworkTitles()
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

}

/// ふりかえり通知へ最後に反映した内容
private struct DailyCompletionReminderSyncState: Equatable {

    let day: Date
    let completedCount: Int

}

/// Siriで言える家事の名前を、最後にOSへ読み直してもらったときの状態
private struct HouseworkTitlesState: Equatable {

    let day: Date
    let statesByTitle: [String: Set<HouseworkState>]

}
