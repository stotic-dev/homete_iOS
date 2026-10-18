//
//  PartnerRegistrationChoice.swift
//  LocalPackage
//

/// オンボーディングのパートナー登録で選んだ方法
public enum PartnerRegistrationChoice: String, CaseIterable, Sendable {

    /// 招待リンクを送る
    case invite
    /// 隣にいる相手とP2Pで登録する
    case nearby
    /// 届いた招待リンクから参加する
    case invited
    /// パートナー登録をあとにする
    case later

}
