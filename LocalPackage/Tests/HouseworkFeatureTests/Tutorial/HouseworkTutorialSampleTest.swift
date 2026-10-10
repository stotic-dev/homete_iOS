//
//  HouseworkTutorialSampleTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkTutorialSampleTest {

    @Test("指定日の家事一覧として、未完了の家事と、パートナーと自分が完了した家事を返す")
    func dailyList_returnsIncompleteAndCompletedItemsOfDay() {
        // Arrange
        let today = Date.previewDate(year: 2026, month: 5, day: 18)

        // Act
        let result = HouseworkTutorialSample.dailyList(today: today, locale: Locale(identifier: "ja"))

        // Assert
        let expected = DailyHouseworkList(
            items: [
                makeItem(id: "tutorial_1", title: "ゴミ出し", point: 10, today: today, executorId: "tutorial_partner"),
                makeItem(id: "tutorial_2", title: "食器洗い", point: 20, today: today, executorId: "tutorial_own"),
                makeItem(id: "tutorial_3", title: "洗濯", point: 20, today: today),
                makeItem(id: "tutorial_4", title: "お風呂掃除", point: 30, today: today),
                makeItem(id: "tutorial_5", title: "夕食の準備", point: 40, today: today),
            ],
            metaData: .init(indexedDate: .init(value: today), expiredAt: .distantFuture)
        )
        #expect(result == expected)
    }

}

private extension HouseworkTutorialSampleTest {

    func makeItem(id: String, title: String, point: Int, today: Date, executorId: String? = nil) -> HouseworkItem {
        .init(
            id: id,
            indexedDate: .init(value: today),
            title: title,
            point: point,
            state: executorId == nil ? .incomplete : .completed,
            executors: executorId.map { [.init(userId: $0, percentage: 100, point: point)] } ?? [],
            effort: .normal,
            executedAt: executorId == nil ? nil : today,
            expiredAt: .distantFuture,
            templateHouseworkItemId: nil
        )
    }

}
