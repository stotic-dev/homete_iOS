//
//  HouseworkThanksStatus.swift
//  homete
//

import HometeDomain
import HometeResources
import SwiftUI

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

    var systemImage: String {
        switch self {
        case .notSent:
            "heart"
        case .sent, .received:
            "heart.fill"
        }
    }

    /// まだ伝えていない家事と、届いたありがとうは目に留まるよう強調し、送り終えたものは控えめにする
    var foregroundStyle: Color {
        switch self {
        case .notSent, .received:
            .accent
        case .sent:
            .onSurfaceVariant
        }
    }

    /// セルに添える文言。アイコンだけで伝わる状況では`nil`
    var label: String? {
        switch self {
        case .notSent, .sent:
            nil
        case .received:
            "ありがとうが届きました"
        }
    }

    /// VoiceOverで読み上げる説明
    var accessibilityLabel: String {
        switch self {
        case .notSent:
            "まだありがとうを伝えていません"
        case .sent:
            "ありがとうを伝えました"
        case .received:
            "ありがとうが届きました"
        }
    }

}

extension HouseworkThanksStatus {

    /// 家事の状態と、見ている本人から、セルに出すありがとうの状況を決める
    ///
    /// 完了済みでない家事と、自分が終えてまだ誰からも届いていない家事は、伝える状況がないため`nil`を返す。
    static func make(item: HouseworkBoardItem, ownUserId: String) -> Self? {
        guard item.state == .completed else { return nil }

        if item.isExecutedBy(ownUserId) {
            return item.originalItem.thanks.isEmpty ? nil : .received
        }
        return item.sentThanks(ownUserId: ownUserId) == nil ? .notSent : .sent
    }

}
