//
//  HouseworkQuickActionMenuContent.swift
//  homete
//

import HometeModel
import SwiftUI

/// 家事のセルを長押しした際に表示する、ステータスに応じたクイックアクションのメニュー内容
///
/// `.contextMenu { }` の中身として使う。並べる操作の判断と実行は`HouseworkQuickActionMenuComponent`が受け持つ
public struct HouseworkQuickActionMenuContent: View {

    let actions: [HouseworkQuickAction]
    let onSelect: (HouseworkQuickAction) -> Void

    public init(actions: [HouseworkQuickAction], onSelect: @escaping (HouseworkQuickAction) -> Void) {
        self.actions = actions
        self.onSelect = onSelect
    }

    public var body: some View {
        ForEach(actions) { action in
            // 取り下げる操作は、ほかの操作と離して押し間違えにくくする
            if action == .remove, action != actions.first {
                Divider()
            }
            Button(action.label, systemImage: action.systemImage, role: action.role) {
                onSelect(action)
            }
        }
    }

}

#if DEBUG
#Preview("HouseworkQuickActionMenuContent_未完了_今日の家事", traits: .sizeThatFitsLayout) {
    // 家事の日付（2026/1/1）を今日にして、「明日にまわす」を出す
    var calendar = Calendar.japanese
    calendar.timeZone = .tokyo
    let actions = HouseworkQuickAction.menuActions(
        for: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        ownUserId: "own",
        canAddHelper: false,
        now: .previewDate(year: 2026, month: 1, day: 1),
        calendar: calendar
    )
    return HouseworkQuickActionMenuContent(actions: actions, onSelect: { _ in })
        .setupEnvironmentForPreview()
}

#Preview("HouseworkQuickActionMenuContent_未完了_昨日の家事", traits: .sizeThatFitsLayout) {
    // 家事の日付（2026/1/1）を昨日にして、「今日にまわす」を出す
    var calendar = Calendar.japanese
    calendar.timeZone = .tokyo
    let actions = HouseworkQuickAction.menuActions(
        for: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        ownUserId: "own",
        canAddHelper: false,
        now: .previewDate(year: 2026, month: 1, day: 2),
        calendar: calendar
    )
    return HouseworkQuickActionMenuContent(actions: actions, onSelect: { _ in })
        .setupEnvironmentForPreview()
}

#Preview("HouseworkQuickActionMenuContent_未完了_一昨日の家事", traits: .sizeThatFitsLayout) {
    // 家事の日付（2026/1/1）を一昨日にして、まわす操作を出さない
    var calendar = Calendar.japanese
    calendar.timeZone = .tokyo
    let actions = HouseworkQuickAction.menuActions(
        for: .makeForPreview(title: "洗濯", point: 10, state: .incomplete),
        ownUserId: "own",
        canAddHelper: false,
        now: .previewDate(year: 2026, month: 1, day: 3),
        calendar: calendar
    )
    return HouseworkQuickActionMenuContent(actions: actions, onSelect: { _ in })
        .setupEnvironmentForPreview()
}

#Preview("HouseworkQuickActionMenuContent_完了_実施者以外_手伝った人を追加できる", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.current
    let actions = HouseworkQuickAction.menuActions(
        for: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "other"
        ),
        ownUserId: "own",
        canAddHelper: true,
        now: .now,
        calendar: calendar
    )
    return HouseworkQuickActionMenuContent(actions: actions, onSelect: { _ in })
}

#Preview("HouseworkQuickActionMenuContent_完了_実施者本人_手伝った人を追加できない", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.current
    let actions = HouseworkQuickAction.menuActions(
        for: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "own"
        ),
        ownUserId: "own",
        canAddHelper: false,
        now: .now,
        calendar: calendar
    )
    return HouseworkQuickActionMenuContent(actions: actions, onSelect: { _ in })
}
#endif
