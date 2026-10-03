//
//  HouseworkQuickActionMenuContent.swift
//  homete
//

import HometeDomain
import SwiftUI

/// 家事のセルを長押しした際に表示する、ステータスに応じたクイックアクションのメニュー内容
///
/// `.contextMenu { }` の中身として使う。
/// 「完了にする」「ありがとう」「手伝った人を追加」は入力用のハーフモーダルを出すため、その場では実行せず
/// `onSelectComplete`・`onSelectThanks`・`onSelectAddHelper`で呼び出し元に伝える
/// （`.contextMenu`の中からはシートを出せないため）。
public struct HouseworkQuickActionMenuContent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.now) var now

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    /// 手伝った人を足せるかどうか（足せる相手がいないときはメニューに出さない）
    let canAddHelper: Bool
    let onSelectComplete: () -> Void
    let onSelectThanks: () -> Void
    let onSelectAddHelper: () -> Void
    let onError: (Error) -> Void

    public init(
        item: HouseworkBoardItem,
        step: HouseworkAnalyticsStep,
        canAddHelper: Bool,
        onSelectComplete: @escaping () -> Void,
        onSelectThanks: @escaping () -> Void,
        onSelectAddHelper: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.item = item
        self.step = step
        self.canAddHelper = canAddHelper
        self.onSelectComplete = onSelectComplete
        self.onSelectThanks = onSelectThanks
        self.onSelectAddHelper = onSelectAddHelper
        self.onError = onError
    }

    public var body: some View {
        ForEach(actions) { action in
            Button(action.label, systemImage: action.systemImage, role: action.role) {
                Task {
                    await perform(action)
                }
            }
        }
    }

}

private extension HouseworkQuickActionMenuContent {

    var actions: [HouseworkQuickAction] {
        HouseworkQuickAction.actions(
            for: item,
            ownUserId: loginContext.account.id,
            canAddHelper: canAddHelper
        )
    }

    func perform(_ action: HouseworkQuickAction) async {
        switch action {
        case .complete:
            onSelectComplete()
            return

        case .sendThanks:
            onSelectThanks()
            return

        case .addHelper:
            onSelectAddHelper()
            return

        case .remove, .redo, .returnToIncomplete:
            break
        }
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
        canAddHelper: false,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}

#Preview("HouseworkQuickActionMenuContent_完了_実施者以外_手伝った人を追加できる", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "other"
        ),
        step: .board,
        canAddHelper: true,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}

#Preview("HouseworkQuickActionMenuContent_完了_実施者本人_手伝った人を追加できない", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "own"
        ),
        step: .board,
        canAddHelper: false,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", fcmToken: nil, cohabitantId: "cohabitant"))
    )
}
#endif
