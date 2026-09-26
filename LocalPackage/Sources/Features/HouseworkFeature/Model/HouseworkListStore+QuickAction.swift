//
//  HouseworkListStore+QuickAction.swift
//  homete
//

import Foundation
import HometeDomain

extension HouseworkListStore {

    /// 家事リストのセルから行うクイックアクションを実行する
    ///
    /// - Parameter notify: 相手への通知を送るかどうか。複数選択の一括操作では、
    ///   家事ごとの個別通知の代わりに件数をまとめた1件の通知を呼び出し側で送るため`false`を渡す。
    // swiftlint:disable:next function_parameter_count
    func perform(
        _ action: HouseworkQuickAction,
        on item: HouseworkBoardItem,
        now: Date,
        account: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws {
        switch action {
        // 担当者やコメントを選ばずに完了にする経路（一括完了）では、自分だけを担当者にする
        case .complete:
            try await complete(
                target: item.originalItem,
                now: now,
                reporter: account,
                executors: [.solo(userId: account.id, point: item.point)],
                executorNames: [account.userName],
                comment: "",
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                step: step,
                notify: notify
            )

        case .remove:
            try await remove(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                step: step
            )

        case .redo:
            try await redo(
                target: item.originalItem,
                now: now,
                executor: account,
                cohabitantId: cohabitantId,
                step: step
            )

        case .sendThanks:
            try await sendThanks(
                target: item.originalItem,
                sender: account,
                comment: action.fixedComment,
                cohabitantId: cohabitantId,
                step: step,
                notify: notify
            )

        case .returnToIncomplete:
            try await returnToIncomplete(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                step: step
            )
        }
    }

}

extension HouseworkListStore {

    /// 複数選択で選んだ家事に、クイックアクションを一括で適用する
    ///
    /// 家事ごとに通知を送ると件数分のPush通知が相手に届いてしまうため、個別の通知は抑制した上で、
    /// 対象件数をまとめた1件の通知だけを送る。完了の通知は、ふりかえり通知の予約を兼ねるため
    /// 今日の家事で1日1回だけ送る。相手に通知しないアクション（やらない・未完了に戻す）では何も送らない。
    // swiftlint:disable:next function_parameter_count
    func performBulk(
        _ action: HouseworkQuickAction,
        on items: [HouseworkBoardItem],
        now: Date,
        account: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws {
        guard let firstItem = items.first else { return }

        for item in items {
            try await perform(
                action,
                on: item,
                now: now,
                account: account,
                cohabitantId: cohabitantId,
                step: step,
                notify: false
            )
        }

        if action == .complete {
            // 複数選択は1日分の家事ボード内で行うため、先頭の家事の日付を代表として使う
            notifyCompleted(
                houseworkDate: firstItem.originalItem.indexedDate.value,
                now: now,
                cohabitantId: cohabitantId
            ) {
                .completedBulkMessage(executorName: account.userName, count: items.count, data: $0)
            }
        }

        let notification = action.bulkNotification(count: items.count, senderName: account.userName)
        guard let notification else { return }

        sendNotification(notification, cohabitantId: cohabitantId)
    }

}
