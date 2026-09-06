//
//  HouseworkQuickActionMenuContent.swift
//  homete
//

import HometeDomain
import SwiftUI

/// 家事のセルを長押しした際に表示する、ステータスに応じたクイックアクションのメニュー内容
///
/// `.contextMenu { }` の中身として使う。
public struct HouseworkQuickActionMenuContent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.now) var now

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    let onError: (Error) -> Void

    public init(item: HouseworkBoardItem, step: HouseworkAnalyticsStep, onError: @escaping (Error) -> Void) {
        self.item = item
        self.step = step
        self.onError = onError
    }

    public var body: some View {
        ForEach(HouseworkQuickAction.actions(for: item, ownUserId: loginContext.account.id)) { action in
            Button(action.label, systemImage: action.systemImage, role: action.role) {
                Task {
                    await perform(action)
                }
            }
        }
    }

}

private extension HouseworkQuickActionMenuContent {

    func perform(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await houseworkListStore.perform(
                action,
                on: item,
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: step
            )
        } catch {
            onError(error)
        }
    }

}

#if DEBUG
#Preview("HouseworkQuickActionMenuContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        step: .board,
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}

#Preview("HouseworkQuickActionMenuContent_承認待ち_確認者", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "other"
        ),
        step: .board,
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}

#Preview("HouseworkQuickActionMenuContent_承認待ち_実施者本人", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "own"
        ),
        step: .board,
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}

#Preview("HouseworkQuickActionMenuContent_完了", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(title: "洗濯", point: 10, state: .completed),
        step: .board,
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}
#endif
