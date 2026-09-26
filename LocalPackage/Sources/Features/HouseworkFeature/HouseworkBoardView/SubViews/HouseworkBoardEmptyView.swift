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

        case .allCompleted:
            EmptyContent(
                systemImage: "checkmark.circle",
                title: "今日の家事は全て終わっています",
                message: "新しい家事が必要な場合は追加しましょう",
                action: ("家事を追加", onCreateTapped)
            )

        case .hasIncompleteHousework:
            EmptyContent(
                systemImage: "list.bullet.clipboard",
                title: "完了した家事はありません",
                message: "未完了の家事があります",
                action: ("未完了を見る", { onSwitchTab(.incomplete) })
            )
        }
    }

}

#Preview("HouseworkBoardEmptyView_家事未登録") {
    HouseworkBoardEmptyView(
        reason: .noHouseworkRegistered,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("HouseworkBoardEmptyView_全て完了") {
    HouseworkBoardEmptyView(
        reason: .allCompleted,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}

#Preview("HouseworkBoardEmptyView_未完了あり") {
    HouseworkBoardEmptyView(
        reason: .hasIncompleteHousework,
        onCreateTapped: {},
        onSwitchTab: { _ in }
    )
}
