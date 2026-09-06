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
    private let analyticsClient: AnalyticsClient

    private let houseworkListObserveKey = "houseworkListObserveKey"

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        analyticsClient: AnalyticsClient = .previewValue,
        items: [DailyHouseworkList] = [],
        idGenerator _: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.analyticsClient = analyticsClient
        self.items = .init(value: items)

        Task {
            await startObserving()
        }
    }

    public func register(
        newItem: HouseworkItem,
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        notification: PushNotificationContent? = nil
    ) async throws {
        do {
            try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)
        } catch {
            analyticsClient.log(.housework(.register(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.register(step: step, isSuccess: true)))

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
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws {
        do {
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
        } catch {
            analyticsClient.log(.housework(.requestReview(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.requestReview(step: step, isSuccess: true)))
    }

    public func approved(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String,
        notify: Bool = true
    ) async throws {
        do {
            try await updateAndSave(
                target: target,
                cohabitantId: cohabitantId,
                transform: { $0.updateApproved(at: now, reviewer: reviwer.id, comment: comment) },
                notification: notify
                    ? {
                        .approvedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
                    }
                    : nil
            )
        } catch {
            analyticsClient.log(.housework(.approve(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.approve(isSuccess: true)))
    }

    public func rejected(
        target: HouseworkItem,
        now: Date,
        reviwer: Account,
        comment: String,
        cohabitantId: String,
        notify: Bool = true
    ) async throws {
        do {
            try await updateAndSave(
                target: target,
                cohabitantId: cohabitantId,
                transform: { $0.updateRejected(at: now, reviewer: reviwer.id, comment: comment) },
                notification: notify
                    ? {
                        .rejectedMessage(reviwerName: reviwer.userName, houseworkTitle: target.title, comment: comment)
                    }
                    : nil
            )
        } catch {
            analyticsClient.log(.housework(.reject(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.reject(isSuccess: true)))
    }

    public func returnToIncomplete(
        target: HouseworkItem,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                $0.updateIncomplete()
            }
        } catch {
            analyticsClient.log(.housework(.returnIncomplete(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.returnIncomplete(step: step, isSuccess: true)))
    }

    public func remove(
        target: HouseworkItem,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            if isRegistered {
                try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                    $0.updateNotTodo()
                }
            } else {
                let updatedItem = target.updateNotTodo()
                try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
            }
        } catch {
            analyticsClient.log(.housework(.delete(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.delete(step: step, isSuccess: true)))
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
