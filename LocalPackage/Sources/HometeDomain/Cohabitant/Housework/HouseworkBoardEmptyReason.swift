//
//  HouseworkBoardEmptyReason.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/04/04.
//

/// 家事ボードの各タブが空のときの理由
public enum HouseworkBoardEmptyReason: Equatable, Sendable {
    /// 家事が1件も登録されていない
    case noHouseworkRegistered
    /// 未完了タブ: 全ての家事が完了または承認待ちに移行済み
    case allCompletedOrPending
    /// 承認待ちタブ: 承認待ちの家事がない
    case noPendingApproval(hasIncomplete: Bool)
    /// 完了タブ: 自身が承認できる承認待ちの家事がある
    case canReviewPendingApproval
    /// 完了タブ: 未完了の家事がある
    case hasIncompleteHousework
    /// 完了タブ: 全ての家事が承認待ちだが自分が実行したため承認待ち
    case allPendingApprovalByOthers

    /// 指定された状態のタブが空のときの理由を返す。表示対象の家事がある場合は `nil`。
    public init?(list: HouseworkBoardList, state: HouseworkState, ownUserId: String) {
        guard list.items(matching: state).isEmpty else { return nil }

        if list.items.isEmpty {
            self = .noHouseworkRegistered
            return
        }

        switch state {
        case .incomplete:
            self = .allCompletedOrPending

        case .pendingApproval:
            let hasIncomplete = !list.items(matching: .incomplete).isEmpty
            self = .noPendingApproval(hasIncomplete: hasIncomplete)

        case .completed:
            let canReview = list.items(matching: .pendingApproval)
                .contains { $0.canReview(ownUserId: ownUserId) }
            if canReview {
                self = .canReviewPendingApproval
            } else if !list.items(matching: .incomplete).isEmpty {
                self = .hasIncompleteHousework
            } else {
                self = .allPendingApprovalByOthers
            }
        }
    }
}
