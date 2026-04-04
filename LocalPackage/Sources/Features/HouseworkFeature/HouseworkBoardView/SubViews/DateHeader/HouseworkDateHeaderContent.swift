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

    @State var dateScrollList: HouseworkDateScrollList
    
    @Binding var selectedDate: Date

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .space8) {
                    ForEach(dateScrollList.dates(calendar: calendar), id: \.self) { date in
                        HouseworkDateCell(
                            date: date,
                            state: dateScrollList.state(for: date, calendar: calendar),
                            onTap: { tappedDate in
                                let updated = dateScrollList.selecting(tappedDate, calendar: calendar)
                                withAnimation { selectedDate = updated.selectedDate }
                            }
                        )
                        .id(date)
                    }
                }
            }
            .onChange(of: selectedDate) {
                withAnimation {
                    proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
            }
        }
    }
}

#Preview {
    HouseworkDateHeaderContent(
        dateScrollList: .init(
            anchorDate: .previewDate(year: 2026, month: 1, day: 1),
            selectedDate: .previewDate(year: 2026, month: 1, day: 1)
        ),
        selectedDate: .constant(.previewDate(year: 2026, month: 1, day: 1))
    )
    .setupEnvironmentForPreview()
}
