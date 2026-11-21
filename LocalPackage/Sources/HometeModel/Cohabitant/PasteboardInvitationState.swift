//
//  PasteboardInvitationState.swift
//  LocalPackage
//

/// クリップボードの招待リンクを確認する案内の状態
public enum PasteboardInvitationState: Equatable, Sendable {

    /// 案内を出さない
    case idle
    /// 「招待リンクを確認する」の案内を出す
    case suggesting
    /// 読み取ったが招待リンクではなかった
    case notFound

}
