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
                        createDateCell(item)
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

private extension HouseworkDateHeaderContent {
    
    func createDateCell(_ item: HouseworkDateList.Item) -> some View {
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
        .visualEffect { content, proxy in
            let frame = proxy.frame(in: .scrollView(axis: .horizontal))
            let scrollWidth = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
            let distanceFromLeft = frame.minX
            let distanceFromRight = scrollWidth - frame.maxX
            let edgeDistance = min(distanceFromLeft, distanceFromRight)
            let threshold: CGFloat = 60
            let progress = max(0, min(1, edgeDistance / threshold))
            return content
                .scaleEffect(0.7 + 0.3 * progress)
                .opacity(progress)
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
