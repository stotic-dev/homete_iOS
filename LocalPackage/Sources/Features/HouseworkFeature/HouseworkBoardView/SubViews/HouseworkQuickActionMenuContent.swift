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
/// 「明日にまわす」「今日にまわす」も、確認のアラートが要るときは`onRequestPostponeConfirmation`で呼び出し元に伝える
/// （呼び出し元は`houseworkPostponeConfirmation`でアラートを出す）。
public struct HouseworkQuickActionMenuContent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    /// 手伝った人を足せるかどうか（足せる相手がいないときはメニューに出さない）
    let canAddHelper: Bool
    let onSelectComplete: () -> Void
    let onSelectThanks: () -> Void
    let onSelectAddHelper: () -> Void
    let onRequestPostponeConfirmation: (HouseworkPostponeConfirmation) -> Void
    let onError: (Error) -> Void

    public init(
        item: HouseworkBoardItem,
        step: HouseworkAnalyticsStep,
        canAddHelper: Bool,
        onSelectComplete: @escaping () -> Void,
        onSelectThanks: @escaping () -> Void,
        onSelectAddHelper: @escaping () -> Void,
        onRequestPostponeConfirmation: @escaping (HouseworkPostponeConfirmation) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.item = item
        self.step = step
        self.canAddHelper = canAddHelper
        self.onSelectComplete = onSelectComplete
        self.onSelectThanks = onSelectThanks
        self.onSelectAddHelper = onSelectAddHelper
        self.onRequestPostponeConfirmation = onRequestPostponeConfirmation
        self.onError = onError
    }

    public var body: some View {
        ForEach(actions) { action in
            // 取り下げる操作は、ほかの操作と離して押し間違えにくくする
            if action == .remove, action != actions.first {
                Divider()
            }
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
        HouseworkQuickAction.menuActions(
            for: item,
            ownUserId: loginContext.account.id,
            canAddHelper: canAddHelper,
            now: now,
            calendar: calendar
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

        case .postponeToTomorrow, .postponeToToday:
            await postponeToNextDay()
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

    /// 家事の日付の翌日へまわす。確かめることがあれば、まわさずに呼び出し元へ伝える
    func postponeToNextDay() async {
        guard let cohabitantId = loginContext.cohabitantId,
              let destination = HouseworkListStore.nextDay(of: item, calendar: calendar) else { return }

        do {
            let result = try await houseworkListStore.postponeIfNeeded(
                item,
                to: destination,
                templateContext: templateContext,
                storagePolicy: storagePolicy,
                cohabitantId: cohabitantId,
                step: step
            )
            if case let .needsConfirmation(confirmation) = result {
                onRequestPostponeConfirmation(confirmation)
            }
        } catch {
            onError(error)
        }
    }

}

#if DEBUG
#Preview("HouseworkQuickActionMenuContent_未完了_今日の家事", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        step: .board,
        canAddHelper: false,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onRequestPostponeConfirmation: { _ in },
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", cohabitantId: "cohabitant"))
    )
    // 家事の日付（2026/1/1）を今日にして、「明日にまわす」を出す
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 1))
    .setupEnvironmentForPreview()
}

#Preview("HouseworkQuickActionMenuContent_未完了_昨日の家事", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        step: .board,
        canAddHelper: false,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onRequestPostponeConfirmation: { _ in },
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", cohabitantId: "cohabitant"))
    )
    // 家事の日付（2026/1/1）を昨日にして、「今日にまわす」を出す
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 2))
    .setupEnvironmentForPreview()
}

#Preview("HouseworkQuickActionMenuContent_未完了_一昨日の家事", traits: .sizeThatFitsLayout) {
    HouseworkQuickActionMenuContent(
        item: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        step: .board,
        canAddHelper: false,
        onSelectComplete: {},
        onSelectThanks: {},
        onSelectAddHelper: {},
        onRequestPostponeConfirmation: { _ in },
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", cohabitantId: "cohabitant"))
    )
    // 家事の日付（2026/1/1）を一昨日にして、まわす操作を出さない
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 3))
    .setupEnvironmentForPreview()
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
        onRequestPostponeConfirmation: { _ in },
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", cohabitantId: "cohabitant"))
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
        onRequestPostponeConfirmation: { _ in },
        onError: { _ in }
    )
    .environment(HouseworkListStore())
    .environment(
        \.loginContext,
        .init(account: .init(id: "own", userName: "", cohabitantId: "cohabitant"))
    )
}
#endif
