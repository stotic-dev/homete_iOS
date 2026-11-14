//
//  HouseworkCompleteViewModel.swift
//  LocalPackage
//

import Foundation
import HometeDomain
import Observation

/// 家事を完了にするハーフモーダルの状態と操作
///
/// iOSの`HouseworkCompleteSheet`とCLI・行動テストが同じものを使う（doc/adr/0072）。
/// UIからは`state`を読み、操作は`send(_:)`で送る。状態の変更は`update(_:)`に集め、非同期の結果も`Message`で戻す。
@MainActor
@Observable
public final class HouseworkCompleteViewModel: Identifiable {

    public struct State: Equatable, Sendable {

        /// 頑張り度と、担当者・ポイントの配分
        public var allocation: HouseworkExecutorAllocation
        /// 配分の調整を開いているか
        public var isExpandedAllocation: Bool
        /// 完了にしている途中か
        public var isCompleting = false
        /// 完了にできたときに担当者へ配ったポイントの合計。入るとほめる演出に切り替える
        public var completedPoint: Int?
        /// 直前の完了が失敗した理由。閉じる操作（`.errorDismissed`）か次の完了で消える
        public var error: DomainError?

        public init(
            allocation: HouseworkExecutorAllocation,
            isExpandedAllocation: Bool = false,
            isCompleting: Bool = false,
            completedPoint: Int? = nil,
            error: DomainError? = nil
        ) {
            self.allocation = allocation
            self.isExpandedAllocation = isExpandedAllocation
            self.isCompleting = isCompleting
            self.completedPoint = completedPoint
            self.error = error
        }

        /// 頑張り度・担当者を変えられるか。完了にしている途中と完了にした後は変えられない
        public var isEditable: Bool {
            !isCompleting && completedPoint == nil
        }

        /// 完了にできるか
        public var canComplete: Bool {
            isEditable && allocation.validationError == nil
        }

        /// 閉じるボタンを出すか。完了にした後は、演出を見せ終わると自動で閉じるので出さない
        public var canClose: Bool {
            isEditable
        }

        /// シートを下へスワイプして閉じられるか。完了にしている途中は閉じられない
        public var canDismiss: Bool {
            !isCompleting
        }

        /// ほめる演出を出しているか
        public var isPraising: Bool {
            completedPoint != nil
        }

    }

    public enum Action: Equatable, Sendable {

        case effortSelected(HouseworkEffort)
        /// 担当者の選択を切り替えた
        case memberToggled(userId: String)
        /// 配分の調整でポイントの割合を変えた
        case percentageChanged(userId: String, percentage: Int)
        /// 画面の部品が配分をまとめて変えた
        case allocationChanged(HouseworkExecutorAllocation)
        case allocationExpandedChanged(Bool)
        case completeTapped
        case closeTapped
        /// ほめる演出を見せ終わった
        case praiseFinished
        /// エラーの表示を閉じた
        case errorDismissed

    }

    /// 親へ返す結果
    public enum Outcome: Equatable, Sendable {

        case completed
        case cancelled

    }

    enum Message {

        case action(Action)
        case completeFinished(Result<Int, DomainError>)

    }

    public nonisolated let id: String
    public let item: HouseworkBoardItem
    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
    public let selectableMembers: [CohabitantMember]
    public private(set) var state: State
    /// 親が提示をやめたか。やめたあとに届いた操作・非同期の結果は捨てる
    public private(set) var isClosed = false

    @ObservationIgnored private let step: HouseworkAnalyticsStep
    @ObservationIgnored private let account: Account
    @ObservationIgnored private let houseworkListStore: HouseworkListStore
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let tasks: TaskTracker
    @ObservationIgnored private let onFinish: @MainActor (Outcome) -> Void

    public init(
        item: HouseworkBoardItem,
        step: HouseworkAnalyticsStep,
        members: CohabitantMemberList,
        account: Account,
        houseworkListStore: HouseworkListStore,
        now: @escaping @MainActor () -> Date,
        tasks: TaskTracker = TaskTracker(),
        onFinish: @escaping @MainActor (Outcome) -> Void
    ) {
        id = item.id
        self.item = item
        // メンバーの読み込み前に開かれても自分だけは選べるようにする
        let selectableMembers = members.value.isEmpty
            ? [.init(id: account.id, userName: account.userName)]
            : members.value
        self.selectableMembers = selectableMembers
        state = State(allocation: .init(
            memberIds: selectableMembers.map(\.id),
            selectedIds: [account.id],
            basePoint: item.originalItem.point
        ))
        self.step = step
        self.account = account
        self.houseworkListStore = houseworkListStore
        self.now = now
        self.tasks = tasks
        self.onFinish = onFinish
    }

    public func send(_ action: Action) {
        update(.action(action))
    }

    /// 親が画面を閉じたときに呼ぶ。以降の操作と、完了にしている途中だった処理の結果を反映しない
    public func close() {
        isClosed = true
    }

}

private extension HouseworkCompleteViewModel {

    func update(_ message: Message) {
        guard !isClosed else { return }
        switch message {
        case let .action(action):
            handle(action)

        case let .completeFinished(.success(point)):
            state.isCompleting = false
            state.completedPoint = point

        case let .completeFinished(.failure(error)):
            // 入力は残し、そのまま再試行できるようにする
            state.isCompleting = false
            state.error = error
        }
    }

    /// 画面からの操作。`update(_:)`の`Message.action`から呼ぶ
    func handle(_ action: Action) {
        let isEditable = state.isEditable
        switch action {
        case let .effortSelected(effort):
            guard isEditable else { return }
            state.allocation.updateEffort(effort)

        case let .memberToggled(userId):
            guard isEditable, state.allocation.canToggle(userId) else { return }
            state.allocation.toggle(userId)

        case let .percentageChanged(userId, percentage):
            guard isEditable else { return }
            state.allocation.updatePercentage(percentage, for: userId)

        case let .allocationChanged(allocation):
            guard isEditable else { return }
            state.allocation = allocation

        case let .allocationExpandedChanged(isExpanded):
            state.isExpandedAllocation = isExpanded

        case .completeTapped:
            // ボタンの非活性だけに頼らず、完了にしている途中の再要求と、確定できない配分はここで捨てる
            guard state.canComplete else { return }
            state.isCompleting = true
            state.error = nil
            complete(allocation: state.allocation)

        case .closeTapped:
            // 完了にしている途中に閉じると「閉じたのに完了になった」ように見えるので、終わるまで受け付けない
            guard state.canDismiss else { return }
            onFinish(state.isPraising ? .completed : .cancelled)

        case .praiseFinished:
            guard state.isPraising else { return }
            onFinish(.completed)

        case .errorDismissed:
            state.error = nil
        }
    }

    func complete(allocation: HouseworkExecutorAllocation) {
        guard let cohabitantId = account.cohabitantId else {
            update(.completeFinished(.failure(.other)))
            return
        }
        tasks.run { [item, step, account, houseworkListStore, now, selectableMembers] in
            let result: Result<Int, DomainError>
            do {
                let executors = try allocation.makeExecutors()
                try await houseworkListStore.complete(
                    target: item.originalItem,
                    now: now(),
                    reporter: account,
                    executors: executors,
                    effort: allocation.effort,
                    executorNames: executors.map { executor in
                        selectableMembers.first { $0.id == executor.userId }?.userName ?? ""
                    },
                    comment: "",
                    cohabitantId: cohabitantId,
                    isRegistered: item.isRegistered,
                    step: step
                )
                result = .success(executors.reduce(0) { $0 + $1.point })
            } catch {
                result = .failure(DomainError.make(error) ?? .other)
            }
            self.update(.completeFinished(result))
        }
    }

}
