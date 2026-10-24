//
//  AccountAuthClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import Foundation

public struct AccountAuthClient: Sendable {

    public let signIn: @Sendable (String, String) async throws -> AccountAuthResult
    public let signOut: @Sendable () throws -> Void
    public let makeListener: @Sendable () -> AccountListenerStream
    /// 端末に保存されているログイン中のユーザー。リスナーを張らずに1回だけ知りたいとき（App Intentなど）に使う
    public let currentAuth: @Sendable () -> AccountAuthResult?
    public let reauthenticateWithApple: @Sendable (_ signInWithAppleResult: SignInWithAppleResult) async throws -> Void
    public let revokeAppleToken: @Sendable (_ authorizationCode: String) async throws -> Void
    public let deleteAccount: @Sendable () async throws -> Void
    /// 匿名認証でサインインする
    public let signInAnonymously: @Sendable () async throws -> AccountAuthResult
    /// 匿名のアカウントにAppleの認証情報を紐づける。uidは変わらない
    /// - Throws: すでに別のアカウントで使われているAppleアカウントなら`AccountLinkError.credentialAlreadyInUse`
    public let linkWithApple: @Sendable (_ tokenId: String, _ nonce: String) async throws -> AccountAuthResult
    /// 連携に失敗したときに受け取った認証情報で、そのAppleアカウントのアカウントへサインインする
    public let signInWithExistingCredential: @Sendable (ExistingAccountCredential) async throws -> AccountAuthResult
    /// サインイン中の匿名アカウントを削除する
    /// - Note: 匿名のアカウントは再認証できないため、最後のサインインから時間がたつと端末からは削除できない。
    ///         サーバー側で削除する
    public let deleteAnonymousAccount: @Sendable () async throws -> Void

    public init(
        signIn: (@Sendable (String, String) async throws -> AccountAuthResult)? = nil,
        signOut: (@Sendable () throws -> Void)? = nil,
        makeListener: (@Sendable () -> AccountListenerStream)? = nil,
        currentAuth: (@Sendable () -> AccountAuthResult?)? = nil,
        reauthenticateWithApple: (@Sendable (_: SignInWithAppleResult) async throws -> Void)? = nil,
        revokeAppleToken: (@Sendable (_ authorizationCode: String) async throws -> Void)? = nil,
        deleteAccount: (@Sendable () async throws -> Void)? = nil,
        signInAnonymously: (@Sendable () async throws -> AccountAuthResult)? = nil,
        linkWithApple: (@Sendable (_ tokenId: String, _ nonce: String) async throws -> AccountAuthResult)? = nil,
        signInWithExistingCredential: (@Sendable (ExistingAccountCredential) async throws -> AccountAuthResult)? = nil,
        deleteAnonymousAccount: (@Sendable () async throws -> Void)? = nil
    ) {
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュする。そのためデフォルト値はnilにして、既定の実装は本体で代入する
        self.signIn = signIn ?? { _, _ in .init(id: "id") }
        self.signOut = signOut ?? {}
        self.makeListener = makeListener ?? {
            let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
            return AccountListenerStream(
                values: stream,
                listenerToken: NSObject(),
                continuation: continuation
            )
        }
        self.currentAuth = currentAuth ?? { nil }
        self.reauthenticateWithApple = reauthenticateWithApple ?? { _ in }
        self.revokeAppleToken = revokeAppleToken ?? { _ in }
        self.deleteAccount = deleteAccount ?? {}
        self.signInAnonymously = signInAnonymously ?? { .init(id: "id", isAnonymous: true) }
        self.linkWithApple = linkWithApple ?? { _, _ in .init(id: "id") }
        self.signInWithExistingCredential = signInWithExistingCredential ?? { _ in .init(id: "id") }
        self.deleteAnonymousAccount = deleteAnonymousAccount ?? {}
    }

}

public extension AccountAuthClient {

    static let previewValue = AccountAuthClient()

}
