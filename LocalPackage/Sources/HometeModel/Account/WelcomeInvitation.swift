//
//  WelcomeInvitation.swift
//  LocalPackage
//

/// ログイン前の説明画面に出す招待の案内
public enum WelcomeInvitation: Equatable, Sendable {

    /// 招待を出さない（招待リンクを開いていない、または取得できなかった）
    case none
    /// 招待が届いている
    /// - Parameter inviterName: 招待者の表示名。名前が無い招待ならnil
    case invited(inviterName: String?)

}
