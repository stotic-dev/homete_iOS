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
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone

    @Binding var dateList: HouseworkDateList

    /// スクロール位置として表示中の日付
    ///
    /// `ScrollViewReader.scrollTo`は`LazyHStack`の未生成セルには届かず、初期表示が
    /// リストの先頭（＝最古の日付）で止まってしまうため、初期値を持てる
    /// `scrollPosition(id:)`で最初のレイアウトから選択日に合わせる。
    @State private var scrolledDate: Date?

    let onTapStorageLimit: () -> Void

    /// 日付セルの高さ。`LazyHStack`は縦方向に提案された高さいっぱいまで広がるため明示する
    private static let cellHeight: CGFloat = 64

    init(dateList: Binding<HouseworkDateList>, onTapStorageLimit: @escaping () -> Void) {
        _dateList = dateList
        _scrolledDate = State(initialValue: dateList.wrappedValue.selectedDate)
        self.onTapStorageLimit = onTapStorageLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text(yearMonthText)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.horizontal, .space8)
            ScrollView(.horizontal, showsIndicators: false) {
                // 保存期間に応じて日付セルが数十〜数百件になるためLazyHStackで遅延生成する
                LazyHStack(spacing: .space8) {
                    if dateList.hasStorageLimit {
                        HouseworkStorageLimitCell(onTap: onTapStorageLimit)
                    }
                    ForEach(dateList.items, id: \.date) { item in
                        createDateCell(item)
                    }
                }
                .scrollTargetLayout()
            }
            .frame(height: Self.cellHeight)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledDate, anchor: .center)
            .onChange(of: dateList.selectedDate) {
                withAnimation {
                    scrolledDate = dateList.selectedDate
                }
            }
        }
    }

}

private extension HouseworkDateHeaderContent {

    var yearMonthText: String {
        let format = Date.FormatStyle(
            locale: locale,
            calendar: calendar,
            timeZone: timeZone
        )
        .year()
        .month()
        return dateList.selectedDate.formatted(format)
    }

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

#if DEBUG
#Preview("HouseworkDateHeaderContent_無料プラン", traits: .sizeThatFitsLayout) {
    HouseworkDateHeaderContent(
        dateList: .constant(.init(
            anchorDate: .previewDate(year: 2026, month: 1, day: 1),
            selectedDate: .previewDate(year: 2026, month: 1, day: 1),
            calendar: .japanese,
            storagePolicy: .free
        )),
        onTapStorageLimit: {}
    )
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 1))
}

#Preview("HouseworkDateHeaderContent_プレミアムプラン", traits: .sizeThatFitsLayout) {
    HouseworkDateHeaderContent(
        dateList: .constant(.init(
            anchorDate: .previewDate(year: 2026, month: 1, day: 1),
            selectedDate: .previewDate(year: 2026, month: 1, day: 1),
            calendar: .japanese,
            storagePolicy: .premium
        )),
        onTapStorageLimit: {}
    )
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 1, day: 1))
}
#endif
