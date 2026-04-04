//
//  HouseworkDateHeaderContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkDateHeaderContent: View {

    @Environment(\.calendar) var calendar

    @Binding var dateList: HouseworkDateList

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .space8) {
                    ForEach(dateList.items, id: \.date) { item in
                        HouseworkDateCell(
                            date: item.date,
                            state: item.state,
                            onTap: { tappedDate in
                                withAnimation {
                                    dateList.selectDate(tappedDate, calendar: calendar)
                                }
                            }
                        )
                        .id(item.date)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .onAppear {
                proxy.scrollTo(calendar.startOfDay(for: dateList.selectedDate), anchor: .center)
            }
            .onChange(of: dateList.selectedDate) {
                withAnimation {
                    proxy.scrollTo(calendar.startOfDay(for: dateList.selectedDate), anchor: .center)
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HouseworkDateHeaderContent(
        dateList: .constant(.init(
            anchorDate: .previewDate(year: 2026, month: 1, day: 1),
            selectedDate: .previewDate(year: 2026, month: 1, day: 1),
            calendar: .japanese
        ))
    )
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 1))
    .snapshotForPreview(delay: 2)
}
