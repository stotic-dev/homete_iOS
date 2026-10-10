//
//  WeekdayLabel.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import HometeDomain
import SwiftUI

/// 曜日を1文字で表示するラベル。選択状態で塗りが変わる
public struct WeekdayLabel: View {

    let weekday: DayOfWeek
    let isSelected: Bool

    public init(weekday: DayOfWeek, isSelected: Bool) {
        self.weekday = weekday
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(weekDayLabel)
            .font(with: .headLineS)
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(isSelected ? .textOnAccent : .textPrimary)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(isSelected ? Color.fillAccent : Color.fillAccentSubtle)
            }
    }

}

private extension WeekdayLabel {

    var weekDayLabel: LocalizedStringResource {
        switch weekday {
        case .sunday: .localized("日", comment: "曜日を選ぶボタンに出すSundayの1文字の略称")
        case .monday: .localized("月", comment: "曜日を選ぶボタンに出すMondayの1文字の略称")
        case .tuesday: .localized("火", comment: "曜日を選ぶボタンに出すTuesdayの1文字の略称")
        case .wednesday: .localized("水", comment: "曜日を選ぶボタンに出すWednesdayの1文字の略称")
        case .thursday: .localized("木", comment: "曜日を選ぶボタンに出すThursdayの1文字の略称")
        case .friday: .localized("金", comment: "曜日を選ぶボタンに出すFridayの1文字の略称")
        case .saturday: .localized("土", comment: "曜日を選ぶボタンに出すSaturdayの1文字の略称")
        }
    }

}

#Preview("WeekdayLabel_未選択", traits: .sizeThatFitsLayout) {
    WeekdayLabel(weekday: .friday, isSelected: false)
}

#Preview("WeekdayLabel_選択中", traits: .sizeThatFitsLayout) {
    WeekdayLabel(weekday: .friday, isSelected: true)
}
