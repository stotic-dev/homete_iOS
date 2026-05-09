//
//  ContributionHelper.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

#if DEBUG

import Foundation
import HometeDomain

extension HouseworkContribution {

    /// Preview・テスト用サンプルデータを生成する
    /// 週・月・年の各表示期間（基準日: 2026-04-30）をカバーするデータを含む
    static func makeForPreview() -> Self {
        let user1Days: [PointOfDay] = [
            // 年間ビュー用 (2025-04-30 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2025, month: 5, day: 10), point: .init(value: 30)),
            .init(indexedDay: .previewDate(year: 2025, month: 6, day: 15), point: .init(value: 20)),
            .init(indexedDay: .previewDate(year: 2025, month: 7, day: 8), point: .init(value: 45)),
            .init(indexedDay: .previewDate(year: 2025, month: 8, day: 22), point: .init(value: 25)),
            .init(indexedDay: .previewDate(year: 2025, month: 9, day: 5), point: .init(value: 35)),
            .init(indexedDay: .previewDate(year: 2025, month: 10, day: 18), point: .init(value: 15)),
            .init(indexedDay: .previewDate(year: 2025, month: 11, day: 12), point: .init(value: 40)),
            .init(indexedDay: .previewDate(year: 2025, month: 12, day: 25), point: .init(value: 50)),
            .init(indexedDay: .previewDate(year: 2026, month: 1, day: 7), point: .init(value: 10)),
            .init(indexedDay: .previewDate(year: 2026, month: 2, day: 14), point: .init(value: 30)),
            .init(indexedDay: .previewDate(year: 2026, month: 3, day: 20), point: .init(value: 25)),
            // 月間ビュー用 (2026-03-30 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 2), point: .init(value: 10)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 8), point: .init(value: 20)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 14), point: .init(value: 15)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 20), point: .init(value: 30)),
            // 週間ビュー用 (2026-04-23 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 24), point: .init(value: 20)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 26), point: .init(value: 15)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 28), point: .init(value: 25)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 30), point: .init(value: 18))
        ]
        let user2Days: [PointOfDay] = [
            // 年間ビュー用 (2025-04-30 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2025, month: 5, day: 20), point: .init(value: 15)),
            .init(indexedDay: .previewDate(year: 2025, month: 6, day: 8), point: .init(value: 35)),
            .init(indexedDay: .previewDate(year: 2025, month: 7, day: 25), point: .init(value: 20)),
            .init(indexedDay: .previewDate(year: 2025, month: 8, day: 10), point: .init(value: 40)),
            .init(indexedDay: .previewDate(year: 2025, month: 9, day: 18), point: .init(value: 10)),
            .init(indexedDay: .previewDate(year: 2025, month: 10, day: 5), point: .init(value: 50)),
            .init(indexedDay: .previewDate(year: 2025, month: 11, day: 28), point: .init(value: 30)),
            .init(indexedDay: .previewDate(year: 2025, month: 12, day: 12), point: .init(value: 25)),
            .init(indexedDay: .previewDate(year: 2026, month: 1, day: 22), point: .init(value: 45)),
            .init(indexedDay: .previewDate(year: 2026, month: 2, day: 5), point: .init(value: 20)),
            .init(indexedDay: .previewDate(year: 2026, month: 3, day: 15), point: .init(value: 35)),
            // 月間ビュー用 (2026-03-30 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 5), point: .init(value: 15)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 11), point: .init(value: 25)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 18), point: .init(value: 10)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 27), point: .init(value: 35)),
            // 週間ビュー用 (2026-04-23 〜 2026-04-30)
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 23), point: .init(value: 10)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 25), point: .init(value: 30)),
            .init(indexedDay: .previewDate(year: 2026, month: 4, day: 29), point: .init(value: 20))
        ]
        return makeForTest(
            list: ["user1": user1Days, "user2": user2Days],
            calendar: .japanese
        )
    }

    static func makeForTest(
        list: [String: [PointOfDay]] = [:],
        calendar: Calendar = .japanese
    ) -> Self {
        let converted: [String: [Date: PointOfDay]] = list.mapValues { pointOfDays in
            Dictionary(
                pointOfDays.map { (calendar.startOfDay(for: $0.indexedDay), $0) },
                uniquingKeysWith: { first, _ in first }
            )
        }
        return .init(list: converted)
    }
}

extension ContributionAnalytics {

    /// Preview用サンプルデータを生成する（基準日: 2026-04-30）
    static func makeForPreview(
        type: DisplayPointPeriod.PeriodType = .month
    ) -> Self {
        let calendar = Calendar.japanese
        let anchor = Date.previewDate(year: 2026, month: 4, day: 30)
        let displayPeriod = DisplayPointPeriod(type: type, anchor: anchor)
        let contribution = HouseworkContribution.makeForPreview()
        let members = CohabitantMemberList(
            value: [
                .init(id: "user1", userName: "田中"),
                .init(id: "user2", userName: "佐藤")
            ],
            ownId: "user1"
        )

        let weekDates = DisplayPointPeriod(type: .week, anchor: anchor)
            .calcDatePeriod(calendar: calendar)
        let monthDates = DisplayPointPeriod(type: .month, anchor: anchor)
            .calcDatePeriod(calendar: calendar)
        let yearDates = DisplayPointPeriod(type: .year, anchor: anchor)
            .calcDatePeriod(calendar: calendar)

        let weekPointList: [PointOfWeek] = contribution.viewablePointList(
            members: members,
            dates: weekDates,
            calendar: calendar
        )
        let monthPointList: [PointOfMonth] = contribution.viewablePointList(
            members: members,
            dates: monthDates,
            calendar: calendar
        )
        let yearPointList: [PointOfYear] = contribution.viewablePointList(
            members: members,
            dates: yearDates,
            calendar: calendar
        )

        return .init(
            weekPointList: weekPointList,
            monthPointList: monthPointList,
            yearPointList: yearPointList,
            displayPeriod: displayPeriod
        )
    }

    static func makeForTest(
        weekPointList: [PointOfWeek] = [],
        monthPointList: [PointOfMonth] = [],
        yearPointList: [PointOfYear] = [],
        displayPeriod: DisplayPointPeriod = .init(
            type: .month,
            anchor: .previewDate(year: 2026, month: 4, day: 30)
        )
    ) -> Self {
        .init(
            weekPointList: weekPointList,
            monthPointList: monthPointList,
            yearPointList: yearPointList,
            displayPeriod: displayPeriod
        )
    }
}

#endif
