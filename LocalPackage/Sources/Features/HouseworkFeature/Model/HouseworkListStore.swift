//
//  HouseworkListStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/27.
//

import Foundation
import HometeDomain
import Observation

@MainActor
@Observable
final class HouseworkListStore {

    private(set) var items: StoredAllHouseworkList
    private var calendar: Calendar = .autoupdatingCurrent

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let houseworkManager: HouseworkManager

    private let houseworkListObserveKey = "houseworkListObserveKey"

    init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        items: [DailyHouseworkList] = []
    ) {

        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.items = .init(value: items)

        Task {
            await startObserving()
        }
    }

    func register(newItem: HouseworkItem, cohabitantId: String) async throws {

        try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)

        Task.detached {

            let notificationContent = PushNotificationContent.addNewHouseworkItem(newItem.title)
            try await self.cohabitantPushNotificationClient.send(cohabitantId, notificationContent)
        }
    }

    func requestReview(
        target: HouseworkItem,
        now: Date,
        executor: String,
        cohabitantId: String
    ) async throws {

        try await updateAndSave(target: target, cohabitantId: cohabitantId) {
            $0.updatePendingApproval(at: now, changer: executor)
        } notification: {
            .requestReviewMessage(houseworkTitle: target.title)
        }
    }

    func approved(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String
    ) async throws {

        try await updateAndSave(target: target, cohabitantId: cohabitantId) {
            $0.updateApproved(at: now, reviewer: reviwer.id, comment: comment)
        } notification: {
            .approvedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
        }
    }

    func rejected(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String
    ) async throws {

        try await updateAndSave(target: target, cohabitantId: cohabitantId) {
            $0.updateRejected(at: now, reviewer: reviwer.id, comment: comment)
        } notification: {
            .rejectedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
        }
    }

    func returnToIncomplete(target: HouseworkItem, cohabitantId: String) async throws {

        try await updateAndSave(target: target, cohabitantId: cohabitantId) {
            $0.updateIncomplete()
        }
    }

    func remove(target: HouseworkItem, cohabitantId: String) async throws {

        try await houseworkClient.removeItem(target, cohabitantId)
    }
}

private extension HouseworkListStore {

    func startObserving() async {

        let stream = await houseworkManager.createObserver(houseworkListObserveKey)
        for await newItems in stream {
            let anchorDate = await houseworkManager.listenerAnchorDate
            items = StoredAllHouseworkList.makeMultiDateList(
                items: newItems,
                anchorDate: anchorDate,
                offsetDays: HouseworkManager.listenerOffset,
                calendar: calendar
            )
        }
    }

    func updateAndSave(
        target: HouseworkItem,
        cohabitantId: String,
        transform: (HouseworkItem) -> HouseworkItem,
        notification: (() -> PushNotificationContent)? = nil
    ) async throws {

        guard let targetItem = items.item(target) else {
            preconditionFailure("Not found target item(\(target))")
        }

        let updatedItem = transform(targetItem)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)

        if let notification {
            let content = notification()
            Task.detached {
                try await self.cohabitantPushNotificationClient.send(
                    cohabitantId,
                    content
                )
            }
        }
    }
}
