//
//  PointsTimeSeriesChartView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import Charts
import HometeDomain
import SwiftUI

struct AllUserViewablePointList<ViewableType: ViewablePointList> {
    let list: [ViewableType]
    let dateRange: ClosedRange<Date>
}

struct PointsTimeSeriesChartView: View {
    let viewableData: AllUserViewablePointList<PointOfMonth>
    
    var body: some View {
        Chart {
            ForEach(viewableData.list, id: \.self) { userData in
                ForEach(Array(userData.elements), id: \.self) { pointOfDay in
                    LineMark(
                        x: .value("日付", pointOfDay.indexedDay, unit: .day),
                        y: .value("ポイント", pointOfDay.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                    PointMark(
                        x: .value("日付", pointOfDay.indexedDay, unit: .day),
                        y: .value("ポイント", pointOfDay.point.value)
                    )
                    .foregroundStyle(by: .value("ユーザー", userData.userName))
                }
            }
        }
        .chartXScale(domain: viewableData.dateRange)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
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
}

#Preview {
    let now = Date.previewDate(year: 2026, month: 4, day: 15)
    let calendar = Calendar.current
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    let dateRange = startOfMonth...endOfMonth

    let pointOfDays1: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 1), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 3), point: .init(value: 20)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 7), point: .init(value: 15)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 10), point: .init(value: 30)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 14), point: .init(value: 25)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 50)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 30), point: .init(value: 10))
    ]
    let pointOfDays2: [PointOfDay] = [
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 2), point: .init(value: 5)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 5), point: .init(value: 12)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 9), point: .init(value: 8)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 13), point: .init(value: 18)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 10)),
        .init(indexedDay: .previewDate(year: 2026, month: 4, day: 30), point: .init(value: 80))
    ]

    PointsTimeSeriesChartView(viewableData: .init(
        list: [
            .make(by: pointOfDays1, userId: "user1", userName: "田中", dateRange: dateRange, calendar: calendar),
            .make(by: pointOfDays2, userId: "user2", userName: "佐藤", dateRange: dateRange, calendar: calendar)
        ],
        dateRange: dateRange
    ))
}
