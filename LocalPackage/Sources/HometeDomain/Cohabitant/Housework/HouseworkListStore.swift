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
        isRegistered: Bool,
        notify: Bool = true
    ) async throws {
        if isRegistered {
            // Houseworksコレクションに登録されている家事の場合はステータスを更新する
            try await updateAndSave(
                target: target,
                cohabitantId: cohabitantId,
                transform: { $0.updatePendingApproval(at: now, changer: executor) },
                notification: notify ? { .requestReviewMessage(houseworkTitle: target.title) } : nil
            )
        } else {
            // 登録されていない場合はドキュメントを新規作成する
            let updatedItem = target.updatePendingApproval(at: now, changer: executor)
            try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
            if notify {
                pushNotificationWithAsync(
                    notification: .requestReviewMessage(houseworkTitle: target.title),
                    cohabitantId: cohabitantId
                )
            }
        }
    }

    public func approved(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String,
        notify: Bool = true
    ) async throws {
        try await updateAndSave(
            target: target,
            cohabitantId: cohabitantId,
            transform: { $0.updateApproved(at: now, reviewer: reviwer.id, comment: comment) },
            notification: notify
                ? { .approvedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment) }
                : nil
        )
    }

    public func rejected(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String,
        notify: Bool = true
    ) async throws {
        try await updateAndSave(
            target: target,
            cohabitantId: cohabitantId,
            transform: { $0.updateRejected(at: now, reviewer: reviwer.id, comment: comment) },
            notification: notify
                ? { .rejectedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment) }
                : nil
        )
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
        cohabitantId: String,
        isRegistered: Bool
    ) async throws {
        if isRegistered {
            try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                $0.updateNotTodo()
            }
        } else {
            let updatedItem = target.updateNotTodo()
            try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        }
    }

    /// 任意の通知内容を相手へ送信する
    ///
    /// 一括操作のように、複数件の更新をまとめて1件の通知にしたい場合に使う。
    public func sendNotification(_ content: PushNotificationContent, cohabitantId: String) {
        pushNotificationWithAsync(notification: content, cohabitantId: cohabitantId)
    }

}

private extension HouseworkListStore {

    func startObserving() async {
        let stream = await houseworkManager.createObserver(houseworkListObserveKey)
        for await result in stream {
            switch result {
            case let .success(newItems):
                let anchorDate = await houseworkManager.listenerAnchorDate
                items = StoredAllHouseworkList.makeMultiDateList(
                    items: newItems,
                    anchorDate: anchorDate,
                    offsetDays: HouseworkManager.listenerOffset,
                    calendar: calendar
                )
                print("did receive current items: \(items)")

            case let .failure(error):
                print("error occurred at housework snapshot listener: \(error)")
            }
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
            pushNotificationWithAsync(notification: content, cohabitantId: cohabitantId)
        }
    }

    func pushNotificationWithAsync(notification: PushNotificationContent, cohabitantId: String) {
        Task.detached {
            try await self.cohabitantPushNotificationClient.send(
                cohabitantId,
                notification
            )
        }
    }

}
