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
    func perform(
        _ action: HouseworkQuickAction,
        on item: HouseworkBoardItem,
        now: Date,
        account: Account,
        cohabitantId: String,
        notify: Bool = true
    ) async throws {
        switch action {
        case .requestReview:
            try await requestReview(
                target: item.originalItem,
                now: now,
                executor: account.id,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                notify: notify
            )

        case .remove:
            try await remove(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered
            )

        case .approve:
            try await approved(
                target: item.originalItem,
                now: now,
                reviwer: account,
                comment: action.fixedComment,
                cohabitantId: cohabitantId,
                notify: notify
            )

        case .reject:
            try await rejected(
                target: item.originalItem,
                now: now,
                reviwer: account,
                comment: action.fixedComment,
                cohabitantId: cohabitantId,
                notify: notify
            )

        case .returnToIncomplete:
            try await returnToIncomplete(
                target: item.originalItem,
                cohabitantId: cohabitantId
            )
        }
    }

}

extension HouseworkListStore {

    /// 複数選択で選んだ家事に、クイックアクションを一括で適用する
    ///
    /// 家事ごとに通知を送ると件数分のPush通知が相手に届いてしまうため、個別の通知は抑制した上で、
    /// 対象件数をまとめた1件の通知だけを送る。相手に通知しないアクション（やらない・差し戻し）では
    /// まとめ通知も送らない。
    func performBulk(
        _ action: HouseworkQuickAction,
        on items: [HouseworkBoardItem],
        now: Date,
        account: Account,
        cohabitantId: String
    ) async throws {
        guard !items.isEmpty else { return }

        for item in items {
            try await perform(
                action,
                on: item,
                now: now,
                account: account,
                cohabitantId: cohabitantId,
                notify: false
            )
        }

        let notification = action.bulkNotification(
            count: items.count,
            reviewerName: account.userName
        )
        guard let notification else { return }

        sendNotification(notification, cohabitantId: cohabitantId)
    }

}
