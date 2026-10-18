//
//  SentInvitationClient.swift
//  LocalPackage
//

import Foundation

/// 最後に送った招待を端末に保存するClient
///
/// 未参加ホームで「参加を待っています」を出すかどうかを、相手の参加を待たずに判定するために使う。
/// 記録は端末単位とし、再インストール・機種変更では引き継がない。
public struct SentInvitationClient: Sendable {

    /// 保存した招待を読み出す。保存していなければ`nil`
    public let load: @Sendable () async -> SentCohabitantInvitation?
    /// 招待を保存する（前に保存したものは上書きする）
    public let save: @Sendable (SentCohabitantInvitation) async -> Void
    /// 保存した招待を消す
    public let clear: @Sendable () async -> Void

    public init(
        load: (@Sendable () async -> SentCohabitantInvitation?)? = nil,
        save: (@Sendable (SentCohabitantInvitation) async -> Void)? = nil,
        clear: (@Sendable () async -> Void)? = nil
    ) {
        // デフォルト引数にasyncクロージャを書くと、Xcode 26でビルドしたテストの並列実行で落ちるため、init本体で埋める
        self.load = load ?? { nil }
        self.save = save ?? { _ in }
        self.clear = clear ?? {}
    }

}

public extension SentInvitationClient {

    static let previewValue: SentInvitationClient = .init()

}

/// 送った招待と、それを送ったアカウント
public struct SentCohabitantInvitation: Equatable, Sendable, Codable {

    /// 招待を送ったアカウントのID
    /// - Note: 匿名のアカウントから既存のアカウントへ切り替えたときは、サインアウトを経ずにアカウントが変わる。
    ///         前のアカウントが送った招待を出さないよう、誰の招待かを持つ
    public let accountId: String
    public let token: String
    public let expiresAt: Date

    public init(accountId: String, token: String, expiresAt: Date) {
        self.accountId = accountId
        self.token = token
        self.expiresAt = expiresAt
    }

}
