//
//  HouseworkPostponeConfirmation.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 家事を別の日へまわす前に、確認のアラートで確かめる内容
///
/// まわす先の家事にまとめるときと、まわす先に同じ名前の家事があるときは、まわす前に確かめる。
/// どちらも、まわした後に家事が思った形で並ばない（1件にまとまる・同じ名前が2件並ぶ）ため。
public struct HouseworkPostponeConfirmation: Identifiable, Equatable, Sendable {

    public enum Reason: Equatable, Sendable {

        /// まわす先の同じテンプレートの家事にまとめる
        case merge
        /// まわす先に同じ名前の家事がある
        case sameTitle

    }

    public let item: HouseworkBoardItem
    public let destination: Date
    public let reason: Reason

    public var id: String {
        item.id
    }

}

extension HouseworkPostponeConfirmation {

    /// 確かめることがなければ`nil`
    init?(item: HouseworkBoardItem, destination: Date, plan: HouseworkPostponePlan) {
        let reason: Reason
        if plan.outcome == .merged {
            reason = .merge
        } else if plan.conflictingTitle != nil {
            reason = .sameTitle
        } else {
            return nil
        }
        self.init(item: item, destination: destination, reason: reason)
    }

}
