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
            .foregroundStyle(.onPrimary2)
            .frame(width: 60, height: 60)
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
        if calendar.dateComponents(
            [.year, .month, .day],
            from: date
        ) == calendar.dateComponents(
            [.year, .month, .day],
            from: now
        ) {
            return "今日"
        } else {
            return String(calendar.component(.day, from: date))
        }
    }
}

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
