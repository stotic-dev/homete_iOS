//
//  HouseworkQuickAction.swift
//  homete
//

import HometeDomain
import SwiftUI

/// 家事リストのセルからワンタップで行えるステータス変更アクション
enum HouseworkQuickAction: Identifiable, Equatable {

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

    /// 状態のみに応じたクイックアクションを返す
    ///
    /// 複数選択での一括操作は、承認待ちの中に自分が実施した項目（レビュー不可）が混ざりうるため、
    /// ここでは実行者に関わらず状態から決まるボタンを返し、実行対象の絞り込みは呼び出し側で行う。
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
