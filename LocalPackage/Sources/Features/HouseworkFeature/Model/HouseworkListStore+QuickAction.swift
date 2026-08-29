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
