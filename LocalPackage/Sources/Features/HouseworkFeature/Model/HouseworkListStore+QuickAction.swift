//
//  HouseworkListStore+QuickAction.swift
//  homete
//

import Foundation
import HometeDomain

extension HouseworkListStore {

    /// 家事リストのセルから行うクイックアクションを実行する
    ///
    /// ありがとうはコメントなしで記録するため、通知しない。
    /// - Returns: このアクションで初めてありがとうを記録したかどうか。ありがとう以外のアクションでは常に`false`
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func perform(
        _ action: HouseworkQuickAction,
        on item: HouseworkBoardItem,
        now: Date,
        account: Account,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> Bool {
        switch action {
        // 担当者やコメントを選ばずに完了にする経路では、自分だけを担当者にする
        case .complete:
            // 頑張り度を選ぶ画面を通らないため「ふつう」で記録し、上乗せ前のポイントを満額配分する
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
                step: step
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
    /// 選んだ家事は1回の書き込みでまとめて反映し、全件成功か全件失敗のどちらかにする。
    /// 家事ごとに通知を送ると件数分のPush通知が相手に届いてしまうため、個別の通知は送らない。
    /// 完了だけは、ふりかえり通知の予約を兼ねて件数をまとめた1件の通知を今日の家事で1日1回だけ送る。
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
        let targets = items.map(\.originalItem)
        switch action {
        case .complete:
            try await completeBulk(
                targets: targets,
                now: now,
                reporter: account,
                cohabitantId: cohabitantId,
                step: step
            )

        case .remove:
            try await removeBulk(targets: targets, cohabitantId: cohabitantId, step: step)

        case .sendThanks:
            return try await sendThanksBulk(
                targets: targets,
                sender: account,
                now: now,
                cohabitantId: cohabitantId,
                step: step
            )

        case .returnToIncomplete:
            try await returnToIncompleteBulk(targets: targets, cohabitantId: cohabitantId, step: step)

        case .redo, .addHelper:
            // 一括操作の対象にしていない（`HouseworkQuickAction.isAvailableInBulk`）
            break
        }
        return false
    }

}
