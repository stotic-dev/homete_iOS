//
//  HouseworkDateCell.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import HometeUI
import HometeDomain
import SwiftUI

struct HouseworkDateCell: View {
    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone
        
    let date: Date
    let state: HouseworkDateState
    var today: Date = .now
    let onTap: (Date) -> Void
    
    var body: some View {
        Button {
            onTap(date)
        } label: {
            Text(dateLabel())
            .font(with: .headLineS)
            .padding(.space16)
            .foregroundStyle(.onPrimary2)
            .background {
                Circle()
                    .fill(state == .unselectable ? .primary3 : .primary2)
            }
            .padding(2)
            .background {
                if state == .selected {
                    Circle()
                        .stroke(lineWidth: 1.5)
                        .fill(.primary1)
                }
            }
        }
    }
}

private extension HouseworkDateCell {
    func dateLabel() -> String {
        if calendar.dateComponents([.year, .month, .day], from: date) == calendar.dateComponents([.year, .month, .day], from: today) {
            return "今日"
        } else {
            return date.formatted(
                Date.FormatStyle(
                    locale: locale,
                    calendar: calendar,
                    timeZone: timeZone
                )
                .day(.defaultDigits)
            )
        }
    }
}

#Preview("今日の日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selected, today: .distantPast) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("選択中の日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selected) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("選択可能な日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .selectable) { _ in }
        .setupEnvironmentForPreview()
}

#Preview("選択不可な日付", traits: .sizeThatFitsLayout) {
    HouseworkDateCell(date: .distantPast, state: .unselectable) { _ in }
        .setupEnvironmentForPreview()
}
