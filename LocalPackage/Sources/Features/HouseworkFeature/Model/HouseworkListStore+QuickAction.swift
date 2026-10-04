//
//  HouseworkListStore+QuickAction.swift
//  homete
//

import Foundation
import HometeDomain

extension HouseworkListStore {

    /// 家事リストのセルから行うクイックアクションを実行する
    ///
    /// - Parameter notify: 完了の通知を送るかどうか。複数選択の一括操作では、
    ///   家事ごとの個別通知の代わりに件数をまとめた1件の通知を呼び出し側で送るため`false`を渡す。
    ///   ありがとうはコメントなしで記録するため、この値に関わらず通知しない。
    /// - Returns: このアクションで初めてありがとうを記録したかどうか。ありがとう以外のアクションでは常に`false`
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func perform(
        _ action: HouseworkQuickAction,
        on item: HouseworkBoardItem,
        now: Date,
        account: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep,
        notify: Bool = true
    ) async throws -> Bool {
        switch action {
        // 担当者やコメントを選ばずに完了にする経路（一括完了）では、自分だけを担当者にする
        case .complete:
            // 一括完了は頑張り度を選ぶ画面を通らないため「ふつう」で記録し、上乗せ前のポイントを満額配分する
            try await complete(
                target: item.originalItem,
                now: now,
                reporter: account,
                executors: [.solo(userId: account.id, point: item.originalItem.point)],
                effort: .normal,
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
            return try await sendThanks(
                target: item.originalItem,
                sender: account,
                comment: nil,
                now: now,
                cohabitantId: cohabitantId,
                step: step
            )

        case .returnToIncomplete:
            try await returnToIncomplete(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                step: step
            )

        case .addHelper:
            // 担当者とポイントの配分をハーフモーダルで決めてから`addHelpers`を呼ぶアクションなので、
            // 入力なしで実行できるこの経路では何もしない（一括操作の対象にもしていない）
            break
        }
        return false
    }

}

extension HouseworkListStore {

    /// 複数選択で選んだ家事に、クイックアクションを一括で適用する
    ///
    /// 家事ごとに通知を送ると件数分のPush通知が相手に届いてしまうため、個別の通知は抑制する。
    /// 完了だけは、ふりかえり通知の予約を兼ねて件数をまとめた1件の通知を今日の家事で1日1回だけ送る。
    /// ほかのアクション（やらない・ありがとう・未完了に戻す）では何も送らない。
    /// - Returns: 1件でも初めてありがとうを記録したかどうか。ありがとう以外のアクションでは常に`false`
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func performBulk(
        _ action: HouseworkQuickAction,
        on items: [HouseworkBoardItem],
        now: Date,
        account: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> Bool {
        guard let firstItem = items.first else { return false }

        var hasSentFirstThanks = false
        for item in items {
            let isFirstThanks = try await perform(
                action,
                on: item,
                now: now,
                account: account,
                cohabitantId: cohabitantId,
                step: step,
                notify: false
            )
            hasSentFirstThanks = hasSentFirstThanks || isFirstThanks
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
        return hasSentFirstThanks
    }

}
