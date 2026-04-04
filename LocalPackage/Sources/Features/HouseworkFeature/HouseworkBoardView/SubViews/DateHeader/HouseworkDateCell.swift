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
            .foregroundStyle(foreground)
            .frame(width: 60, height: 60)
            .background {
                Circle()
                    .fill(background)
            }
            .padding(2)
            .background {
                if let borderColor {
                    Circle()
                        .stroke(lineWidth: 1.5)
                        .fill(borderColor)
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
    
    struct CellContent {
        let foreground: Color
        let background: Color
        let borderColor: Color?
    }
    
    var foreground: Color {
        switch state {
        case .selected: .onPrimary1
        case .selectable: .onPrimary2
        case .unselectable: .onPrimary3
        }
    }
    
    var background: Color {
        switch state {
        case .selected: .primary1
        case .selectable: .primary2
        case .unselectable: .primary3
        }
    }
    
    var borderColor: Color? {
        switch state {
        case .selected: .primary2
        case .selectable, .unselectable: nil
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
