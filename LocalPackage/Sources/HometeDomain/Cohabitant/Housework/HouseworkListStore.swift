//
//  HouseworkListStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/27.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class HouseworkListStore {

    public private(set) var items: StoredAllHouseworkList
    private var calendar: Calendar = .autoupdatingCurrent

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let houseworkManager: HouseworkManager

    private let houseworkListObserveKey = "houseworkListObserveKey"

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        items: [DailyHouseworkList] = [],
        idGenerator _: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.items = .init(value: items)

        Task {
            await startObserving()
        }
    }

    public func register(
        newItem: HouseworkItem,
        cohabitantId: String,
        notification: PushNotificationContent? = nil
    ) async throws {
        try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)

        Task.detached {
            let notificationContent = notification ?? PushNotificationContent.addNewHouseworkItem(newItem.title)
            try await self.cohabitantPushNotificationClient.send(cohabitantId, notificationContent)
        }
    }

    public func requestReview(
        target: HouseworkItem,
        now: Date,
        executor: String,
        cohabitantId: String,
        isRegistered: Bool
    ) async throws {
        if isRegistered {
            // Houseworksコレクションに登録されている家事の場合はステータスを更新する
            try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                $0.updatePendingApproval(at: now, changer: executor)
            } notification: {
                .requestReviewMessage(houseworkTitle: target.title)
            }
        } else {
            // 登録されていない場合はドキュメントを新規作成する
            let updatedItem = target.updatePendingApproval(at: now, changer: executor)
            try await register(
                newItem: updatedItem,
                cohabitantId: cohabitantId,
                notification: .requestReviewMessage(houseworkTitle: target.title)
            )
        }
    }

    public func approved(
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

    public func rejected(
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

    public func returnToIncomplete(
        target: HouseworkItem,
        cohabitantId: String
    ) async throws {
        try await updateAndSave(target: target, cohabitantId: cohabitantId) {
            $0.updateIncomplete()
        }
    }

    public func remove(
        target: HouseworkItem,
        cohabitantId: String
    ) async throws {
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
            print("did receive current items: \(items)")
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
