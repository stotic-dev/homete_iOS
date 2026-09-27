//
//  HouseworkThanksMessage.swift
//  homete
//

import HometeDomain

/// 家事詳細に出す、誰から届いたありがとうか
struct HouseworkThanksMessage: Equatable {

    /// メッセージを書かずに伝えたありがとうの表示
    static let defaultMessage = "ありがとう！"

    let senderName: String
    let message: String

}

extension HouseworkThanksMessage {

    /// 家事に届いたありがとうを、送られた順に並べる
    ///
    /// グループを抜けたなどで名前が分からない人のありがとうは、誰からか伝えられないため出さない。
    static func make(item: HouseworkBoardItem, memberList: CohabitantMemberList) -> [Self] {
        item.originalItem.thanks
            .sorted { ($0.value.sentAt, $0.key) < ($1.value.sentAt, $1.key) }
            .compactMap { senderId, thanks in
                guard let senderName = memberList.userName(senderId) else { return nil }

                return .init(senderName: senderName, message: thanks.comment ?? defaultMessage)
            }
    }

}
