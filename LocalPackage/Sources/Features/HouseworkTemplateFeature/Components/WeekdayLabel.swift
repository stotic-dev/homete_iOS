//
//  WeekdayLabel.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import HometeDomain
import HometeUI
import SwiftUI

struct WeekdayLabel: View {

    let weekday: DayOfWeek
    let isSelected: Bool

    var body: some View {
        Text(weekDayLabel)
            .font(with: .headLineS)
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(isSelected ? .onPrimary1 : .onSurface)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(isSelected ? Color.primary1 : Color.primary3)
            }
    }

}

private extension WeekdayLabel {

    var weekDayLabel: String {
        switch weekday {
        case .sunday: "日"
        case .monday: "月"
        case .tuesday: "火"
        case .wednesday: "水"
        case .thursday: "木"
        case .friday: "金"
        case .saturday: "土"
        }
    }

}

#Preview("WeekdayLabel_未選択", traits: .sizeThatFitsLayout) {
    WeekdayLabel(weekday: .friday, isSelected: false)
}

#Preview("WeekdayLabel_選択中", traits: .sizeThatFitsLayout) {
    WeekdayLabel(weekday: .friday, isSelected: true)
}
