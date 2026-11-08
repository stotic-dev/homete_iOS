//
//  HouseworkThanksMessage.swift
//  homete
//


/// 家事詳細に出す、誰から届いたありがとうか
public struct HouseworkThanksMessage: Equatable, Sendable {

    public let senderName: String
    /// 添えられたコメント。メッセージを書かずに伝えたありがとうは`nil`
    public let comment: String?

    public init(
        senderName: String,
        comment: String?
    ) {
        self.senderName = senderName
        self.comment = comment
    }

}

public extension HouseworkThanksMessage {

    /// 家事に届いたありがとうを、送られた順に並べる
    ///
    /// グループを抜けたなどで名前が分からない人のありがとうは、誰からか伝えられないため出さない。
    static func make(item: HouseworkBoardItem, memberList: CohabitantMemberList) -> [Self] {
        item.originalItem.thanks
            .sorted { ($0.value.sentAt, $0.key) < ($1.value.sentAt, $1.key) }
            .compactMap { senderId, thanks in
                guard let senderName = memberList.userName(senderId) else { return nil }

                return .init(senderName: senderName, comment: thanks.comment)
            }
    }

}
