//
//  HouseworkDateCell.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkDateCell: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone
    @Environment(\.now) var now

    let date: Date
    let state: HouseworkDateState
    /// 昨日以前で、まだ終わっていない家事がある日か。右上に印を付ける
    var hasPastIncomplete = false
    let onTap: (Date) -> Void

    var body: some View {
        Button {
            onTap(date)
        } label: {
            Text(dateLabel())
                .font(with: .headLineS)
                .padding(.space8)
                .foregroundStyle(foreground)
                .frame(width: 60, height: 60)
                .background {
                    Circle()
                        .fill(background)
                        .strokeBorder(border, lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if hasPastIncomplete {
                        pastIncompleteBadge
                    }
                }
                .padding(2)
        }
        .accessibilityValue(hasPastIncomplete ? Text("やり残している家事があります", bundle: #bundle) : Text(verbatim: ""))
    }

}

private extension HouseworkDateCell {

    /// やり残している家事がある日の印。日付の丸の背景色に埋もれないよう、カードの色で縁取る
    var pastIncompleteBadge: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(with: .body)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.textOnDestructive, .fillDestructive)
            .background {
                Circle()
                    .fill(.backgroundCard)
            }
            .accessibilityHidden(true)
    }

    func dateLabel() -> LocalizedStringResource {
        if calendar.dateComponents(
            [.year, .month, .day],
            from: date
        ) == calendar.dateComponents(
            [.year, .month, .day],
            from: now
        ) {
            .localized("今日")
        } else {
            .localized("\(calendar.component(.day, from: date))", comment: "日付の行に出す日にち（例: 25）")
        }
    }

    struct CellContent {

        let foreground: Color
        let background: Color

    }

    var foreground: Color {
        switch state {
        case .selected: .textOnAccent
        case .selectable: .textPrimary
        case .unselectable: .textSecondary
        }
    }

    var background: Color {
        switch state {
        case .selected: .fillAccent
        case .selectable: .fillAccentSubtle
        // 塗りのある選べる日と見分けられるよう、選べない日は塗らずに輪郭線だけで丸を見せる。
        // カードの色で塗ると、ミルク色の地の上では選べる日より目立ってしまう
        case .unselectable: .clear
        }
    }

    var border: Color {
        switch state {
        case .selected, .selectable: .clear
        case .unselectable: .textSecondary.opacity(0.3)
        }
    }

}

#if DEBUG
#Preview("HouseworkDateCell_今日の日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selected) { _ in }
        .setupEnvironmentForPreview()
        .environment(\.now, .distantPast)
}

#Preview("HouseworkDateCell_選択中の日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selected) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("HouseworkDateCell_選択可能な日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selectable) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("HouseworkDateCell_やり残しがある日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selectable, hasPastIncomplete: true) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("HouseworkDateCell_やり残しがある選択中の日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selected, hasPastIncomplete: true) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("HouseworkDateCell_選択不可な日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .unselectable) { _ in }
        .setupEnvironmentForPreview()
}
#endif
