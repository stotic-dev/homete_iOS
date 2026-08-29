//
//  HouseworkQuickAction.swift
//  homete
//

import HometeDomain
import SwiftUI

/// 家事リストのセルからワンタップで行えるステータス変更アクション
enum HouseworkQuickAction: Identifiable, Equatable, CaseIterable {

    /// 承認依頼（未完了 → 承認待ち）
    case requestReview
    /// やらない（未完了 → やらない）
    case remove
    /// ありがとう（承認待ち → 完了）
    case approve
    /// 再確認依頼（承認待ち → 未完了）
    case reject
    /// 差し戻し（完了 → 未完了）
    case returnToIncomplete

    var id: Self {
        self
    }

    var label: String {
        switch self {
        case .requestReview:
            "承認依頼"
        case .remove:
            "やらない"
        case .approve:
            "ありがとう"
        case .reject:
            "再確認依頼"
        case .returnToIncomplete:
            "差し戻し"
        }
    }

    var systemImage: String {
        switch self {
        case .requestReview:
            "paperplane.fill"
        case .remove:
            "trash"
        case .approve:
            "checkmark.circle.fill"
        case .reject:
            "arrow.triangle.2.circlepath"
        case .returnToIncomplete:
            "arrow.uturn.backward"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .remove:
            .destructive
        case .requestReview, .approve, .reject, .returnToIncomplete:
            nil
        }
    }

}

extension HouseworkQuickAction {

    /// ワンタップ実行時に自動設定する定型コメント（`approve`/`reject`のみ使用）
    var fixedComment: String {
        switch self {
        case .approve:
            "ありがとう！"
        case .reject:
            "再確認をお願いします"
        case .requestReview, .remove, .returnToIncomplete:
            ""
        }
    }

    /// 一括操作で相手に送る、まとめ通知の内容
    ///
    /// 家事ごとに個別通知を送ると件数分の通知が届いてしまうため、一括操作では対象件数をまとめた
    /// 1件の通知のみを送る。相手に何も通知しないアクション（やらない・差し戻し）は`nil`。
    func bulkNotification(count: Int, reviewerName: String) -> PushNotificationContent? {
        switch self {
        case .requestReview:
            .requestReviewBulkMessage(count: count)
        case .approve:
            .approvedBulkMessage(reviwerName: reviewerName, count: count)
        case .reject:
            .rejectedBulkMessage(count: count)
        case .remove, .returnToIncomplete:
            nil
        }
    }

}

extension HouseworkQuickAction {

    /// 家事の状態・実行者に応じて、その家事に対して行えるクイックアクションを返す
    static func actions(for item: HouseworkBoardItem, ownUserId: String) -> [Self] {
        if item.state == .pendingApproval, !item.canReview(ownUserId: ownUserId) {
            [.returnToIncomplete]
        } else {
            actions(for: item.state)
        }
    }

    /// 選択中の家事に対して行えるクイックアクションを、重複なく列挙順で返す
    ///
    /// 同じステータスでも実行者によって行えるアクションは変わる（承認待ちでも自分が承認依頼を出した
    /// 家事は差し戻ししか行えない）。一括操作バーのボタンをタブのステータスから決め打ちすると、
    /// 選択内容によっては実行できないボタンだけが非活性で並ぶため、選択中の家事から実際に行える
    /// アクションを集めて表示する。
    static func availableActions(for items: [HouseworkBoardItem], ownUserId: String) -> [Self] {
        let available = Set(items.flatMap { actions(for: $0, ownUserId: ownUserId) })
        return allCases.filter(available.contains)
    }

    /// 状態のみに応じたクイックアクションを返す
    ///
    /// 一括操作バーで、まだ何も選択されていないときに表示する既定のボタンを決めるために使う。
    static func actions(for state: HouseworkState) -> [Self] {
        switch state {
        case .incomplete:
            [.requestReview, .remove]

        case .pendingApproval:
            [.approve, .reject]

        case .completed:
            [.returnToIncomplete]

        case .notTodo:
            []
        }
    }

}
