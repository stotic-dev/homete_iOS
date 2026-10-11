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
                }
                .padding(2)
        }
    }

}

private extension HouseworkDateCell {

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
        case .unselectable: .backgroundScreen
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

#Preview("HouseworkDateCell_選択不可な日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .unselectable) { _ in }
        .setupEnvironmentForPreview()
}
#endif
