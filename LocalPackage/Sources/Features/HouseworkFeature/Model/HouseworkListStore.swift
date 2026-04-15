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
    private var cohabitantId: String
    private var calendar: Calendar = .autoupdatingCurrent

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let houseworkManager: HouseworkManager

    private let houseworkListObserveKey = "houseworkListObserveKey"

    init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        items: [DailyHouseworkList] = [],
        cohabitantId: String = ""
    ) {

        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.items = .init(value: items)
        self.cohabitantId = cohabitantId

        Task {
            await startObserving()
        }
    }

    func loadHouseworkList(currentTime: Date, cohabitantId: String, calendar: Calendar) async {

        self.cohabitantId = cohabitantId
        self.calendar = calendar

        // すでに監視処理のセットアップ済みなら、後続の処理は行わない
        guard !cohabitantId.isEmpty else { return }

        await houseworkManager.setupObserver(
            currentTime: currentTime,
            cohabitantId: cohabitantId,
            calendar: calendar,
            offset: 3
        )
    }

    func register(_ newItem: HouseworkItem) async throws {

        try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)

        Task.detached {

            let notificationContent = PushNotificationContent.addNewHouseworkItem(newItem.title)
            try await self.cohabitantPushNotificationClient.send(self.cohabitantId, notificationContent)
        }
    }

    func requestReview(target: HouseworkItem, now: Date, executor: String) async throws {

        try await updateAndSave(target: target) {
            $0.updatePendingApproval(at: now, changer: executor)
        } notification: {
            .requestReviewMessage(houseworkTitle: target.title)
        }
    }

    func approved(target: HouseworkItem, now: Date, reviwer: Account, comment: String) async throws {

        try await updateAndSave(target: target) {
            $0.updateApproved(at: now, reviewer: reviwer.id, comment: comment)
        } notification: {
            .approvedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
        }
    }

    func rejected(target: HouseworkItem, now: Date, reviwer: Account, comment: String) async throws {

        try await updateAndSave(target: target) {
            $0.updateRejected(at: now, reviewer: reviwer.id, comment: comment)
        } notification: {
            .rejectedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
        }
    }

    func returnToIncomplete(target: HouseworkItem) async throws {

        try await updateAndSave(target: target) {
            $0.updateIncomplete()
        }
    }

    func remove(_ target: HouseworkItem) async throws {

        try await houseworkClient.removeItem(target, cohabitantId)
    }
}

private extension HouseworkListStore {

    func startObserving() async {

        let stream = await houseworkManager.createObserver(houseworkListObserveKey)
        for await newItems in stream {
            items = StoredAllHouseworkList.makeMultiDateList(items: newItems, calendar: calendar)
        }
    }

    func updateAndSave(
        target: HouseworkItem,
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
                    self.cohabitantId,
                    content
                )
            }
        }
    }
}
