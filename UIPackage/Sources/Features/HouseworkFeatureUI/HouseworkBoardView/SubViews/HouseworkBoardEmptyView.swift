//
//  HouseworkBoardEmptyView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import HometeModel
import HometeUI
import SwiftUI

public struct HouseworkBoardEmptyView: View {

    let reason: HouseworkBoardEmptyReason
    let onCreateTapped: () -> Void
    let onSwitchTab: (HouseworkState) -> Void

    public init(
        reason: HouseworkBoardEmptyReason,
        onCreateTapped: @escaping () -> Void,
        onSwitchTab: @escaping (HouseworkState) -> Void
    ) {
        self.reason = reason
        self.onCreateTapped = onCreateTapped
        self.onSwitchTab = onSwitchTab
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(content.title)
            } icon: {
                icon
            }
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

        public let icon: Icon
        public let title: LocalizedStringResource
        public let message: LocalizedStringResource?
        public let action: (label: LocalizedStringResource, handler: () -> Void)?

        public init(
            icon: Icon,
            title: LocalizedStringResource,
            message: LocalizedStringResource?,
            action: (label: LocalizedStringResource, handler: () -> Void)?
        ) {
            self.icon = icon
            self.title = title
            self.message = message
            self.action = action
        }

    }

    enum Icon {

        case homette(HometteExpression)
        case systemImage(String)

    }

    @ViewBuilder
    var icon: some View {
        switch content.icon {
        case let .homette(expression):
            HometteView(expression)

        case let .systemImage(name):
            Image(systemName: name)
        }
    }

    var content: EmptyContent {
        switch reason {
        case .noHouseworkRegistered:
            EmptyContent(
                icon: .homette(.cheer),
                title: .localized("今日の家事はまだありません"),
                message: .localized("やる家事を追加すると、ここに並びます"),
                action: (.localized("家事を追加"), onCreateTapped)
            )

        case .allCompleted:
            EmptyContent(
                icon: .homette(.rest),
                title: .localized("今日の家事は、ぜんぶ終わりました"),
                message: .localized("おつかれさまでした。ゆっくり休んでくださいね"),
                action: (.localized("家事を追加"), onCreateTapped)
            )

        case .hasIncompleteHousework:
            EmptyContent(
                icon: .systemImage("list.bullet.clipboard"),
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
