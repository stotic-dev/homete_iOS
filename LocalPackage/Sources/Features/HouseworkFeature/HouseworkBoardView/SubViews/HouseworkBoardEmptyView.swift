//
//  HouseworkBoardEmptyView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import HometeDomain
import SwiftUI

struct HouseworkBoardEmptyView: View {

    let reason: HouseworkBoardEmptyReason
    let onCreateTapped: () -> Void
    let onSwitchTab: (HouseworkState) -> Void

    var body: some View {
        ContentUnavailableView {
            Label(content.title, systemImage: content.systemImage)
        } description: {
            if let message = content.message {
                Text(message)
            }
        } actions: {
            if let action = content.action {
                Button(action.label, action: action.handler)
                    .subPrimaryButtonStyle()
            }
        }
    }
}

private extension HouseworkBoardEmptyView {

    struct EmptyContent {
        let systemImage: String
        let title: String
        let message: String?
        let action: (label: String, handler: () -> Void)?
    }

    var content: EmptyContent {
        switch reason {
        case .noHouseworkRegistered:
            EmptyContent(
                systemImage: "checklist",
                title: "今日の家事を追加しましょう",
                message: nil,
                action: ("家事を追加", onCreateTapped)
            )

        case .allCompletedOrPending:
            EmptyContent(
                systemImage: "checkmark.circle",
                title: "全ての家事が完了または承認中です",
                message: "新しい家事が必要な場合は追加しましょう",
                action: ("家事を追加", onCreateTapped)
            )

        case .noPendingApproval(let hasIncomplete):
            EmptyContent(
                systemImage: "clock.badge.checkmark",
                title: "承認待ちの家事はありません",
                message: nil,
                action: hasIncomplete
                    ? ("未完了を見る", { onSwitchTab(.incomplete) })
                    : nil
            )

        case .canReviewPendingApproval:
            EmptyContent(
                systemImage: "person.badge.clock",
                title: "完了した家事はありません",
                message: "承認待ちの家事があります",
                action: ("承認待ちを見る", { onSwitchTab(.pendingApproval) })
            )

        case .hasIncompleteHousework:
            EmptyContent(
                systemImage: "list.bullet.clipboard",
                title: "完了した家事はありません",
                message: "未完了の家事があります",
                action: ("未完了を見る", { onSwitchTab(.incomplete) })
            )

        case .allPendingApprovalByOthers:
            EmptyContent(
                systemImage: "hourglass",
                title: "完了した家事はありません",
                message: "今日の家事は全て承認待ちです",
                action: nil
            )
        }
    }
}

#Preview("家事未登録") {
    HouseworkBoardEmptyView(
        reason: .noHouseworkRegistered,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("全て完了または承認中") {
    HouseworkBoardEmptyView(
        reason: .allCompletedOrPending,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("承認待ちなし（未完了あり）") {
    HouseworkBoardEmptyView(
        reason: .noPendingApproval(hasIncomplete: true),
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("承認待ちなし（未完了もなし）") {
    HouseworkBoardEmptyView(
        reason: .noPendingApproval(hasIncomplete: false),
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("承認できる承認待ちあり") {
    HouseworkBoardEmptyView(
        reason: .canReviewPendingApproval,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("未完了あり") {
    HouseworkBoardEmptyView(
        reason: .hasIncompleteHousework,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("全て自分の承認待ち") {
    HouseworkBoardEmptyView(
        reason: .allPendingApprovalByOthers,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}
