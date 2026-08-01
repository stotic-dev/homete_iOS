//
//  WeekdaySelector.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 月〜日を複数選択するセグメント風コンポーネント。
struct WeekdaySelector: View {

    @Binding var selection: Set<DayOfWeek>

    var body: some View {
        HStack(spacing: .space8) {
            ForEach(DayOfWeek.displayOrdered) { day in
                Button {
                    toggle(day)
                } label: {
                    WeekdayLabel(weekday: day, isSelected: selection.contains(day))
                }
                .buttonStyle(.plain)
            }
        }
    }

}

private extension WeekdaySelector {

    func toggle(_ day: DayOfWeek) {
        if selection.contains(day) {
            selection.remove(day)
        } else {
            selection.insert(day)
        }
    }

}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    WeekdaySelector(selection: .constant([.monday, .wednesday]))
        .padding()
}
#endif
