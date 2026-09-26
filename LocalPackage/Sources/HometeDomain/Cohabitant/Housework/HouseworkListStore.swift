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
    /// 家事のスナップショットリスナーの購読状態
    public private(set) var loadState: ListenerLoadState = .loading
    private let calendar: Calendar
    private let now: @MainActor @Sendable () -> Date
    /// 最後にふりかえり通知へ反映した「日付と、その日に完了した家事の件数」
    /// - Note: スナップショットは家事が1件変わるたびに届くため、結果が変わったときだけ予約し直す。
    ///         件数で見るのは、1日1回の制限を外している間（デバッグ用）に完了のたびに予約を積むため
    private var lastReminderSyncState: DailyCompletionReminderSyncState?

    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
    private let houseworkManager: HouseworkManager
    private let analyticsClient: AnalyticsClient
    private let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase

    private let houseworkListObserveKey = "houseworkListObserveKey"

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        analyticsClient: AnalyticsClient = .previewValue,
        dailyCompletionReminderUseCase: DailyCompletionReminderUseCase = .init(client: .previewValue),
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping @MainActor @Sendable () -> Date = { .now },
        items: [DailyHouseworkList] = [],
        idGenerator _: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.houseworkManager = houseworkManager
        self.analyticsClient = analyticsClient
        self.dailyCompletionReminderUseCase = dailyCompletionReminderUseCase
        self.calendar = calendar
        self.now = now
        self.items = .init(value: items)

        Task {
            await startObserving()
        }
    }

    /// 家事を登録する
    /// - Note: 登録を同居人へは通知しない。家事のステータスに関わる通知は、ふりかえり通知だけにしている
    public func register(
        newItem: HouseworkItem,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)
        } catch {
            analyticsClient.log(.housework(.register(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.register(step: step, isSuccess: true)))
    }

    /// 家事を完了にする
    ///
    /// 同居人へは表示する通知を送らず、同居人の端末でふりかえり通知を予約するためのサイレント通知だけを送る。
    /// - Parameter notify: 一括操作では1件分のサイレント通知を呼び出し側で送るため`false`を渡す。
    // swiftlint:disable:next function_parameter_count
    public func complete(
        target: HouseworkItem,
        now: Date,
        executor: Account,
        cohabitantId: String,
        isRegistered: Bool,
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws {
        do {
            if isRegistered {
                // Houseworksコレクションに登録されている家事の場合はステータスを更新する
                try await updateAndSave(target: target, cohabitantId: cohabitantId) {
                    $0.updateCompleted(at: now, executor: executor.id)
                }
            } else {
                // 登録されていない場合はドキュメントを新規作成する
                let updatedItem = target.updateCompleted(at: now, executor: executor.id)
                try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
            }
        } catch {
            analyticsClient.log(.housework(.complete(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.complete(step: step, isSuccess: true)))

        if notify {
            notifyCompleted(houseworkDate: target.indexedDate.value, now: now, cohabitantId: cohabitantId)
        }
    }

    /// 完了した家事に「ありがとう」を伝える
    ///
    /// 家事のステータスは変えず、相手への通知だけを送る。通知の送信そのものがこの操作の成果なので、
    /// 他の操作のように送りっぱなしにはせず、完了を待って失敗は呼び出し元に返す。
    ///
    /// - Parameter notify: 一括操作では件数をまとめた1件の通知を呼び出し側で送るため`false`を渡す。
    public func sendThanks(
        target: HouseworkItem,
        sender: Account,
        comment: String,
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws {
        do {
            if notify {
                try await cohabitantPushNotificationClient.send(
                    cohabitantId,
                    .thanksMessage(
                        senderName: sender.userName,
                        houseworkTitle: target.title,
                        comment: comment
                    )
                )
            }
        } catch {
            analyticsClient.log(.housework(.sendThanks(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.sendThanks(step: step, isSuccess: true)))
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

    /// 同居人の端末でふりかえり通知を予約するため、家事の完了をサイレント通知で知らせる
    ///
    /// 送るのは今日の家事の完了で、かつこの端末からその日まだ送っていないときだけ（ベストエフォート）。
    /// 送信は待たずに行い、失敗しても家事の操作は失敗扱いにしない。
    public func notifyCompleted(houseworkDate: Date, now: Date, cohabitantId: String) {
        let calendar = calendar
        Task.detached {
            do {
                try await self.dailyCompletionReminderUseCase.notifyCompletedIfNeeded(
                    houseworkDate: houseworkDate,
                    now: now,
                    calendar: calendar
                ) { data in
                    try await self.cohabitantPushNotificationClient.sendSilent(cohabitantId, data.payload)
                }
            } catch {
                print("failed to notify cohabitants of completed housework: \(error)")
            }
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
                loadState = .loaded
                await syncDailyCompletionReminder()

            case let .failure(error):
                print("error occurred at housework snapshot listener: \(error)")
                loadState = .failed(error)
            }
        }
    }

    func updateAndSave(
        target: HouseworkItem,
        cohabitantId: String,
        transform: (HouseworkItem) -> HouseworkItem
    ) async throws {
        guard let targetItem = items.item(target) else {
            preconditionFailure("Not found target item(\(target))")
        }

        let updatedItem = transform(targetItem)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
    }

    /// 今日完了した家事があるかを、ふりかえり通知の予約に反映する
    func syncDailyCompletionReminder() async {
        let currentDate = now()
        let completedCount = items.value
            .filter { calendar.isDate($0.metaData.indexedDate.value, inSameDayAs: currentDate) }
            .flatMap(\.items)
            .count { $0.state == .completed }
        let syncState = DailyCompletionReminderSyncState(
            day: calendar.startOfDay(for: currentDate),
            completedCount: completedCount
        )
        guard syncState != lastReminderSyncState else { return }

        lastReminderSyncState = syncState
        await dailyCompletionReminderUseCase.syncToday(
            hasCompletedHousework: completedCount > .zero,
            now: currentDate,
            calendar: calendar
        )
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

/// ふりかえり通知へ最後に反映した内容
private struct DailyCompletionReminderSyncState: Equatable {

    let day: Date
    let completedCount: Int

}
