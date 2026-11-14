//
//  PartnerInvitationShareState.swift
//  LocalPackage
//

import HometeModel

/// オンボーディングのパートナー登録で、招待リンクをどこまで共有したか
public enum PartnerInvitationShareState: Hashable, Sendable {

    /// まだ共有シートを閉じていない
    case notShared
    /// 共有シートを閉じたが、共有を完了したと分からなかった
    /// - Note: 共有先のアプリによっては、送っても完了と伝えてこない
    case unconfirmed
    /// 共有を完了した
    case shared

}
