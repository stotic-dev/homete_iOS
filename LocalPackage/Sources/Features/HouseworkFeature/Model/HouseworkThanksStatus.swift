//
//  HouseworkThanksStatus.swift
//  homete
//

import HometeDomain

/// 完了リストの家事セルに出す、ありがとうの状況
///
/// 見ている本人の目線で、まだありがとうを伝えていない家事と、自分の家事にありがとうが届いたことを
/// 一覧から見分けられるようにする。
enum HouseworkThanksStatus: Equatable, CaseIterable {

    /// 自分以外が終えた家事に、まだ送っていない
    case notSent
    /// 自分以外が終えた家事に、送った
    case sent
    /// 自分が終えた家事に、ありがとうが届いた
    case received

}

extension HouseworkThanksStatus {

    /// 家事の状態と、見ている本人から、セルに出すありがとうの状況を決める
    ///
    /// 完了済みでない家事と、自分が終えてまだ誰からも届いていない家事は、伝える状況がないため`nil`を返す。
    /// 自分を含む複数人で担当した家事は、他の担当者へ伝えられるため、届いた状況より自分が伝えたかどうかを優先して出す。
    static func make(item: HouseworkBoardItem, ownUserId: String) -> Self? {
        if item.isThankable(by: ownUserId) {
            return item.sentThanks(ownUserId: ownUserId) == nil ? .notSent : .sent
        }
        guard item.state == .completed, item.isExecutedBy(ownUserId) else { return nil }

        let hasReceivedThanks = item.originalItem.thanks.keys.contains { $0 != ownUserId }
        return hasReceivedThanks ? .received : nil
    }

}
