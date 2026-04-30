//
//  ContributionAnalyticsView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import Charts
import HometeUI
import SwiftUI

struct ContributionAnalyticsView: View {

    let monthlyPoints: [PointOfMonth]
    let userNames: [String: String]

    @Environment(\.now) var now
    @Environment(\.calendar) var calendar

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(chartTitle)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.horizontal, .space16)
                .padding(.top, .space16)
            Chart {
                ForEach(monthlyPoints, id: \.userId) { pointOfMonth in
                    let userName = userNames[pointOfMonth.userId] ?? pointOfMonth.userId
                    let sortedElements = pointOfMonth.elements.sorted { $0.indexedDay < $1.indexedDay }
                    ForEach(sortedElements, id: \.indexedDay) { pointOfDay in
                        LineMark(
                            x: .value("日付", pointOfDay.indexedDay, unit: .day),
                            y: .value("ポイント", pointOfDay.point.value)
                        )
                        .foregroundStyle(by: .value("ユーザー", userName))
                        PointMark(
                            x: .value("日付", pointOfDay.indexedDay, unit: .day),
                            y: .value("ポイント", pointOfDay.point.value)
                        )
                        .foregroundStyle(by: .value("ユーザー", userName))
                    }
                }
            }
            .chartXScale(domain: monthDateRange)
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
            .frame(height: 240)
            .padding(.horizontal, .space16)
            .padding(.bottom, .space16)
        }
    }

    private var chartTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月のポイント推移"
    }

    private var monthDateRange: ClosedRange<Date> {
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components) ?? now
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: startOfMonth
        ) ?? now
        return startOfMonth...endOfMonth
    }
}

#Preview("ContributionAnalyticsView_データ有り", traits: .sizeThatFitsLayout) {
    let now = Date.previewDate(year: 2026, month: 4, day: 15)
    let calendar = Calendar.current

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

    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    let dateRange = startOfMonth...endOfMonth

    let monthlyPoints: [PointOfMonth] = [
        .make(by: pointOfDays1, userId: "user1", userName: "田中", dateRange: dateRange, calendar: calendar),
        .make(by: pointOfDays2, userId: "user2", userName: "佐藤", dateRange: dateRange, calendar: calendar)
    ]
    let userNames: [String: String] = ["user1": "田中", "user2": "佐藤"]

    ContributionAnalyticsView(monthlyPoints: monthlyPoints, userNames: userNames)
        .environment(\.now, now)
        .setupEnvironmentForPreview()
}

#Preview("ContributionAnalyticsView_データ無し", traits: .sizeThatFitsLayout) {
    ContributionAnalyticsView(monthlyPoints: [], userNames: [:])
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
        .setupEnvironmentForPreview()
}
