//
//  HouseworkPostponeConfirmation.swift
//  LocalPackage
//

import Foundation

/// 家事を別の日へまわす前に、確認のアラートで確かめる内容
///
/// まわす先の家事にまとめるときと、まわす先に同じ名前の家事があるときは、まわす前に確かめる。
/// どちらも、まわした後に家事が思った形で並ばない（1件にまとまる・同じ名前が2件並ぶ）ため。
/// テンプレートの家事に画像を添えているときも、まわすと画像が見られなくなるため確かめる。
public struct HouseworkPostponeConfirmation: Identifiable, Equatable, Sendable {

    public enum Reason: Equatable, Sendable {


        /// まわす先の同じテンプレートの家事にまとめる
        case merge
        /// まわす先に同じ名前の家事がある
        case sameTitle
        /// 添えた画像がまわす先に引き継がれず、見られなくなる
        case leavesImages

    }

    public let item: HouseworkBoardItem
    public let destination: Date
    public let reason: Reason

    public init(
        item: HouseworkBoardItem,
        destination: Date,
        reason: Reason
    ) {
        self.item = item
        self.destination = destination
        self.reason = reason
    }

    public var id: String {
        item.id
    }

}

public extension HouseworkPostponeConfirmation {

    /// 確かめることがなければ`nil`
    /// - Note: 画像が見られなくなることは取り返しがつかないため、まとめる・同じ名前よりも優先して伝える
    init?(item: HouseworkBoardItem, destination: Date, plan: HouseworkPostponePlan) {
        let reason: Reason
        if plan.leavesImagesBehind {
            reason = .leavesImages
        } else if plan.outcome == .merged {
            reason = .merge
        } else if plan.conflictingTitle != nil {
            reason = .sameTitle
        } else {
            return nil
        }
        self.init(item: item, destination: destination, reason: reason)
    }

}
