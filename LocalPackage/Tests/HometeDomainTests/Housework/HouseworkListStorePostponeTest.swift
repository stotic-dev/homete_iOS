//
//  HouseworkListStorePostponeTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkListStorePostponeTest {

    private let inputCohabitantId = "cohabitantId"
    /// まわす前の日（2026/1/10）
    private let sourceDate = Date.previewDate(year: 2026, month: 1, day: 10)
    /// まわす先の日（2026/1/11）
    private let destinationDate = Date.previewDate(year: 2026, month: 1, day: 11)

    @Test("家事をまわすと、まわす先へ移した家事を1回の一括書き込みで保存し、Analyticsに移したことを送る")
    func postpone_singleItem_writesInOneBatchAndLogsMoved() async throws {
        // Arrange
        let inputItem = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: sourceDate,
            title: "洗濯",
            expiredAt: .previewDate(year: 2027, month: 1, day: 10)
        )
        let expectedItems = [
            HouseworkItem.makeForTest(
                id: "1",
                indexedDate: destinationDate,
                title: "洗濯",
                expiredAt: .previewDate(year: 2027, month: 1, day: 11),
                postponedFrom: .init(value: sourceDate)
            ),
        ]
        let logger = TestBox<[AnalyticsEvent]>(value: [])

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(insertOrUpdateItemsHandler: { items, cohabitantId in
                    // Assert
                    #expect(items == expectedItems)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                analyticsClient: .init(log: { event in logger.value.append(event) }),
                calendar: .japanese,
                items: [.makeForTest(items: [inputItem])]
            )

            // Act
            let actual = try await store.postpone(
                target: inputItem,
                isRegistered: true,
                to: destinationDate,
                templateContext: .init(metadata: nil, houseworkTemplate: []),
                storagePolicy: .free,
                cohabitantId: inputCohabitantId,
                step: .board
            )

            // Assert
            #expect(actual == .moved)
            #expect(logger.value == [.housework(.postpone(step: .board, outcome: .moved, isSuccess: true))])
        }
    }

    @Test("画面を開いている間に同居人が完了にしていた家事は、まわさない")
    func postpone_latestRecordCompleted_doesNothing() async throws {
        // Arrange
        let inputItem = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: sourceDate,
            title: "洗濯"
        )
        let latestItem = HouseworkItem.makeForTest(
            id: "1",
            indexedDate: sourceDate,
            title: "洗濯",
            state: .completed,
            executorId: "partner"
        )
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { _ in Issue.record() }),
            calendar: .japanese,
            items: [.makeForTest(items: [latestItem])]
        )

        // Act
        let actual = try await store.postpone(
            target: inputItem,
            isRegistered: true,
            to: destinationDate,
            templateContext: .init(metadata: nil, houseworkTemplate: []),
            storagePolicy: .free,
            cohabitantId: inputCohabitantId,
            step: .board
        )

        // Assert
        #expect(actual == nil)
    }

    @Test("テンプレートから出していた家事を、画面を開いている間に同居人が完了にしていたら、まわさない")
    func postpone_unregisteredTemplateItemRegisteredByPartner_doesNothing() async throws {
        // Arrange
        let templateItemId = HouseworkTemplateItem.ItemId(id: "template1")
        let inputItem = HouseworkItem.makeForTest(
            id: "virtual",
            indexedDate: sourceDate,
            title: "お皿洗い",
            templateHouseworkItemId: templateItemId
        )
        let registeredByPartner = HouseworkItem.makeForTest(
            id: "registered",
            indexedDate: sourceDate,
            title: "お皿洗い",
            state: .completed,
            executorId: "partner",
            templateHouseworkItemId: templateItemId
        )
        let store = HouseworkListStore(
            houseworkClient: .init(insertOrUpdateItemsHandler: { _, _ in Issue.record() }),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { _ in Issue.record() }),
            calendar: .japanese,
            items: [.makeForTest(items: [registeredByPartner])]
        )

        // Act
        let actual = try await store.postpone(
            target: inputItem,
            isRegistered: false,
            to: destinationDate,
            templateContext: .init(metadata: nil, houseworkTemplate: []),
            storagePolicy: .free,
            cohabitantId: inputCohabitantId,
            step: .board
        )

        // Assert
        #expect(actual == nil)
    }

}
