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
                    .primaryButtonStyle()
            }
        }
    }

}

private extension HouseworkBoardEmptyView {

    struct EmptyContent {

        let systemImage: String
        let title: LocalizedStringResource
        let message: LocalizedStringResource?
        let action: (label: LocalizedStringResource, handler: () -> Void)?

    }

    var content: EmptyContent {
        switch reason {
        case .noHouseworkRegistered:
            EmptyContent(
                systemImage: "checklist",
                title: .localized("今日の家事はまだありません"),
                message: .localized("やる家事を追加すると、ここに並びます"),
                action: (.localized("家事を追加"), onCreateTapped)
            )

        case .allCompleted:
            EmptyContent(
                systemImage: "checkmark.circle",
                title: .localized("今日の家事は、ぜんぶ終わりました"),
                message: .localized("おつかれさまでした。ゆっくり休んでくださいね"),
                action: (.localized("家事を追加"), onCreateTapped)
            )

        case .hasIncompleteHousework:
            EmptyContent(
                systemImage: "list.bullet.clipboard",
                title: .localized("完了した家事はありません"),
                message: .localized("未完了の家事があります"),
                action: (.localized("未完了を見る"), { onSwitchTab(.incomplete) })
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
