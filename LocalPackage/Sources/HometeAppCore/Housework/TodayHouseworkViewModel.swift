//
//  TodayHouseworkViewModel.swift
//  LocalPackage
//

import Foundation
import HometeDomain
import Observation

/// ダッシュボードの「今日の家事」の状態と操作
///
/// iOSの`TodayHouseworkSummaryComponent`とCLI・行動テストが同じものを使う（doc/adr/0072）。
/// 家事の一覧の正は`HouseworkListStore`で、`summary`はその写しを今日の分に絞ったもの。
/// 完了にするハーフモーダルを出すか（`completion`）はこのViewModelを唯一の正にする。
@MainActor
@Observable
public final class TodayHouseworkViewModel {

    /// 一覧を組み立てるのに使う、画面の外から決まる値
    public struct Context: Equatable, Sendable {

        public var now: Date
        /// 今日の曜日・日付に当てはまる家事テンプレート。無ければ`nil`
        public var template: HouseworkTemplateDay?
        public var members: CohabitantMemberList
        /// 操作している本人
        public var account: Account

        public init(now: Date, template: HouseworkTemplateDay?, members: CohabitantMemberList, account: Account) {
            self.now = now
            self.template = template
            self.members = members
            self.account = account
        }

    }

    public enum Action: Equatable, Sendable {

        /// 日付・テンプレート・メンバー・ログイン中のアカウントが変わった
        case contextChanged(Context)
        /// 家事の「完了にする」を押した
        case completeTapped(itemId: String)
        /// 完了にするハーフモーダルを下へスワイプして閉じた
        case completionDismissed

    }

    public private(set) var context: Context
    /// 出している、完了にするハーフモーダル
    public private(set) var completion: HouseworkCompleteViewModel?

    @ObservationIgnored private let houseworkListStore: HouseworkListStore
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let tasks: TaskTracker

    public init(
        context: Context,
        houseworkListStore: HouseworkListStore,
        calendar: Calendar,
        tasks: TaskTracker = TaskTracker()
    ) {
        self.context = context
        self.houseworkListStore = houseworkListStore
        self.calendar = calendar
        self.tasks = tasks
    }

    /// 今日の家事の一覧と進み具合
    public var summary: TodayHouseworkSummary {
        .make(
            storedAllItems: houseworkListStore.items,
            template: context.template,
            now: context.now,
            calendar: calendar
        )
    }

    public func send(_ action: Action) {
        switch action {
        case let .contextChanged(context):
            self.context = context

        case let .completeTapped(itemId):
            // 別の家事のシートを出している間は受け付けない
            guard completion == nil,
                  let item = summary.incompleteItems.first(where: { $0.id == itemId }) else { return }
            presentCompletion(for: item)

        case .completionDismissed:
            // 完了にしている途中は閉じられない
            guard let completion, completion.state.canDismiss else { return }
            closeCompletion()
        }
    }

}

private extension TodayHouseworkViewModel {

    func presentCompletion(for item: HouseworkBoardItem) {
        let viewModel = HouseworkCompleteViewModel(
            item: item,
            step: .dashboard,
            members: context.members,
            account: context.account,
            houseworkListStore: houseworkListStore,
            now: { [weak self] in self?.context.now ?? .now },
            tasks: tasks
        ) { [weak self] _ in
            self?.closeCompletion()
        }
        completion = viewModel
    }

    func closeCompletion() {
        completion?.close()
        completion = nil
    }

}
