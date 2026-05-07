//
//  PointsTimeSeriesChartView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import Charts
import HometeDomain
import HometeUI
import SwiftUI

struct PointsTimeSeriesChartView: View {

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    
    let viewableData: AllUserViewablePointList
    
    @State private var selectedDate: Date?

    init(viewableData: AllUserViewablePointList, selectedDate: Date? = nil) {
        self.viewableData = viewableData
        self._selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        Chart {
            ForEach(viewableData.list, id: \.self) { userData in
                let sortedElements = Array(userData.elements).sorted { $0.date < $1.date }
                ForEach(sortedElements, id: \.self) { element in
                    LineMark(
                        x: .value("日付", element.date),
                        y: .value("ポイント", element.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                    PointMark(
                        x: .value("日付", element.date),
                        y: .value("ポイント", element.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                }
            }
            if let date = selectedDate {
                RuleMark(x: .value("日付", date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .annotation(
                        position: .top,
                        alignment: .center,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        selectionPopup(
                            for: viewableData.pointEntries(for: date, calendar: calendar),
                            selectedDate: date
                        )
                    }
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, position: .bottom, values: xAxisStride) { _ in
                AxisValueLabel(
                    format: xLabelFormat,
                    multiLabelAlignment: .leading
                )
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel("\(value.as(Int.self) ?? 0)pt")
            }
        }
        .chartLegend(position: .bottom, alignment: .center)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
    }
}

// MARK: UI定義

private extension PointsTimeSeriesChartView {
    
    var xAxisStride: AxisMarkValues {
        switch viewableData.displayPeriod {
        case .week:
            return .automatic(desiredCount: 7)
        case .month:
            return .automatic(desiredCount: 5)
        case .year:
            return .automatic(desiredCount: 12)
        }
    }

    var xLabelFormat: Date.FormatStyle {
        var style: Date.FormatStyle
        switch viewableData.displayPeriod {
        case .year: style = .dateTime.month(.defaultDigits).locale(locale)
        case .month: style = .dateTime.day().locale(locale)
        case .week: style = .dateTime.weekday(.abbreviated).locale(locale)
        }
        style.timeZone = timeZone
        return style
    }

    var popupDateFormat: Date.FormatStyle {
        var style: Date.FormatStyle
        switch viewableData.displayPeriod {
        case .year: style = .dateTime.year().month().locale(locale)
        case .month, .week: style = .dateTime.month().day().locale(locale)
        }
        style.timeZone = timeZone
        return style
    }

    @ViewBuilder
    func selectionPopup(for entries: [AllUserViewablePointList.PointEntry], selectedDate: Date) -> some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text(selectedDate, format: popupDateFormat)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
            if entries.isEmpty {
                Text("データ無し")
                    .font(with: .boldCaption)
            } else {
                ForEach(entries) { entry in
                    Text("\(entry.userName): \(entry.point)pt")
                        .font(with: .boldCaption)
                }
            }
        }
        .padding(.horizontal, .space8)
        .padding(.vertical, .space4)
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

// MARK: プレゼンテーションロジック

private extension PointsTimeSeriesChartView {
    
    func handleTap(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        
        let frame = geometry.frame(in: .local)
        guard let tapDate: Date = proxy.value(atX: location.x - frame.minX) else { return }
        guard let nearest = viewableData.nearestDate(to: tapDate) else {
            selectedDate = nil
            return
        }
        selectedDate = selectedDate == nearest ? nil : nearest
    }
}

#Preview("PointsTimeSeriesChartView_週間 (日別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    let weekEnd = Date.previewDate(year: 2026, month: 4, day: 26)
    let period = DisplayPointPeriod(type: .week, anchor: weekEnd)
    // swiftlint:disable:next force_unwrapping
    let dateRange = period.calcDateRange(calendar: calendar)!

    let pointOfDays1: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 21), point: .init(value: 30)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 23), point: .init(value: 15)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 25), point: .init(value: 20)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 26), point: .init(value: 10))
    ]
    let pointOfDays2: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 5)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 22), point: .init(value: 25)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 24), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 26), point: .init(value: 20))
    ]

    PointsTimeSeriesChartView(
        viewableData: AllUserViewablePointList.make(
            list: [
                PointOfWeek.make(
                    by: pointOfDays1,
                    userId: "user1",
                    userName: "田中",
                    dateRange: dateRange,
                    calendar: calendar
                ),
                PointOfWeek.make(
                    by: pointOfDays2,
                    userId: "user2",
                    userName: "佐藤",
                    dateRange: dateRange,
                    calendar: calendar
                )
            ],
            displayPeriod: .week,
            dateRange: dateRange,
            calendar: calendar
        ),
        selectedDate: .previewDate(year: 2026, month: 4, day: 20)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("PointsTimeSeriesChartView_月間 (日別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    let period = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    // swiftlint:disable:next force_unwrapping
    let dateRange = period.calcDateRange(calendar: calendar)!

    let pointOfDays1: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 1), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 7), point: .init(value: 20)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 14), point: .init(value: 15)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 30)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 28), point: .init(value: 25))
    ]
    let pointOfDays2: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 3), point: .init(value: 5)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 10), point: .init(value: 18)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 28), point: .init(value: 40))
    ]

    PointsTimeSeriesChartView(
        viewableData: AllUserViewablePointList.make(
            list: [
                PointOfMonth.make(
                    by: pointOfDays1,
                    userId: "user1",
                    userName: "田中",
                    dateRange: dateRange,
                    calendar: calendar
                ),
                PointOfMonth.make(
                    by: pointOfDays2,
                    userId: "user2",
                    userName: "佐藤",
                    dateRange: dateRange,
                    calendar: calendar
                )
            ],
            displayPeriod: .month,
            dateRange: dateRange,
            calendar: calendar
        ),
        selectedDate: .previewDate(year: 2026, month: 4, day: 7)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("PointsTimeSeriesChartView_年間 (月別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    // swiftlint:disable:next force_unwrapping
    let yearEnd = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
    let period = DisplayPointPeriod(
        type: .year,
        anchor: yearEnd
    )
    // swiftlint:disable:next force_unwrapping
    let dateRange = period.calcDateRange(calendar: calendar)!

    let points1 = [30, 15, 45, 20, 50, 35, 25, 40, 10, 45, 30, 20]
    let points2 = [20, 40, 25, 45, 30, 15, 50, 20, 35, 25, 45, 30]
    let pointOfDays1: [PointOfDay] = (1...12).map { month in
        PointOfDay(indexedDay: .previewDate(year: 2026, month: month, day: 10), point: .init(value: points1[month - 1]))
    }
    let pointOfDays2: [PointOfDay] = (1...12).map { month in
        PointOfDay(indexedDay: .previewDate(year: 2026, month: month, day: 20), point: .init(value: points2[month - 1]))
    }

    PointsTimeSeriesChartView(
        viewableData: AllUserViewablePointList.make(
            list: [
                PointOfYear.make(
                    by: pointOfDays1,
                    userId: "user1",
                    userName: "田中",
                    dateRange: dateRange,
                    calendar: calendar
                ),
                PointOfYear.make(
                    by: pointOfDays2,
                    userId: "user2",
                    userName: "佐藤",
                    dateRange: dateRange,
                    calendar: calendar
                )
            ],
            displayPeriod: .year,
            dateRange: dateRange,
            calendar: calendar
        ),
        selectedDate: .previewDate(year: 2026, month: 4, day: 1)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}
