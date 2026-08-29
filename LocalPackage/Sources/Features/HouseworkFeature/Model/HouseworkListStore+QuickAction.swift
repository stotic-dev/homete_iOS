//
//  HouseworkListStore+QuickAction.swift
//  homete
//

import Foundation
import HometeDomain

extension HouseworkListStore {

    /// 家事リストのセルから行うクイックアクションを実行する
    func perform(
        _ action: HouseworkQuickAction,
        on item: HouseworkBoardItem,
        now: Date,
        account: Account,
        cohabitantId: String
    ) async throws {
        switch action {
        case .requestReview:
            try await requestReview(
                target: item.originalItem,
                now: now,
                executor: account.id,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered
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
                cohabitantId: cohabitantId
            )

        case .reject:
            try await rejected(
                target: item.originalItem,
                now: now,
                reviwer: account,
                comment: action.fixedComment,
                cohabitantId: cohabitantId
            )

        case .returnToIncomplete:
            try await returnToIncomplete(
                target: item.originalItem,
                cohabitantId: cohabitantId
            )
        }
    }

}
