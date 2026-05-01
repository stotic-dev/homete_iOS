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
    let viewableData: AllUserViewablePointList

    @Environment(\.locale) private var locale

    var body: some View {
        Chart {
            ForEach(viewableData.list, id: \.self) { userData in
                let sortedElements = Array(userData.elements).sorted { $0.date < $1.date }
                ForEach(sortedElements, id: \.self) { element in
                    LineMark(
                        x: .value("日付", element.date, unit: xUnit),
                        y: .value("ポイント", element.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                    PointMark(
                        x: .value("日付", element.date, unit: xUnit),
                        y: .value("ポイント", element.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: viewableData.xAxisDates) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(
                    format: xLabelFormat,
                    multiLabelAlignment: .center
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
    }

    private var xUnit: Calendar.Component {
        switch viewableData.displayPeriod {
        case .year: return .month
        case .month, .week: return .day
        }
    }

    private var xLabelFormat: Date.FormatStyle {
        switch viewableData.displayPeriod {
        case .year: return .dateTime.month(.defaultDigits).locale(locale)
        case .month: return .dateTime.day().locale(locale)
        case .week: return .dateTime.weekday(.abbreviated).locale(locale)
        }
    }
}

#Preview("週間 (日別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    let weekEnd = Date.previewDate(year: 2026, month: 4, day: 26)
    let period = DisplayPointPeriod(type: .week, anchor: weekEnd)
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

    PointsTimeSeriesChartView(viewableData: AllUserViewablePointList.make(
        list: [
            PointOfWeek.make(by: pointOfDays1, userId: "user1", userName: "田中", dateRange: dateRange, calendar: calendar),
            PointOfWeek.make(by: pointOfDays2, userId: "user2", userName: "佐藤", dateRange: dateRange, calendar: calendar)
        ],
        displayPeriod: .week,
        dateRange: dateRange,
        calendar: calendar
    ))
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("月間 (日別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    let period = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
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

    PointsTimeSeriesChartView(viewableData: AllUserViewablePointList.make(
        list: [
            PointOfMonth.make(by: pointOfDays1, userId: "user1", userName: "田中", dateRange: dateRange, calendar: calendar),
            PointOfMonth.make(by: pointOfDays2, userId: "user2", userName: "佐藤", dateRange: dateRange, calendar: calendar)
        ],
        displayPeriod: .month,
        dateRange: dateRange,
        calendar: calendar
    ))
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("年間 (月別)", traits: .sizeThatFitsLayout) {
    let calendar = Calendar.japanese
    let yearStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let yearEnd = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
    let period = DisplayPointPeriod(
        type: .year,
        anchor: yearEnd
    )
    let dateRange = period.calcDateRange(calendar: calendar)!

    let points1 = [30, 15, 45, 20, 50, 35, 25, 40, 10, 45, 30, 20]
    let points2 = [20, 40, 25, 45, 30, 15, 50, 20, 35, 25, 45, 30]
    let pointOfDays1: [PointOfDay] = (1...12).map { month in
        PointOfDay(indexedDay: .previewDate(year: 2026, month: month, day: 10), point: .init(value: points1[month - 1]))
    }
    let pointOfDays2: [PointOfDay] = (1...12).map { month in
        PointOfDay(indexedDay: .previewDate(year: 2026, month: month, day: 20), point: .init(value: points2[month - 1]))
    }

    PointsTimeSeriesChartView(viewableData: AllUserViewablePointList.make(
        list: [
            PointOfYear.make(by: pointOfDays1, userId: "user1", userName: "田中", dateRange: dateRange, calendar: calendar),
            PointOfYear.make(by: pointOfDays2, userId: "user2", userName: "佐藤", dateRange: dateRange, calendar: calendar)
        ],
        displayPeriod: .year,
        dateRange: dateRange,
        calendar: calendar
    ))
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}
