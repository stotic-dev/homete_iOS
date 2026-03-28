//
//  AccountListener.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import Foundation

public struct AccountAuthClient: Sendable {

    public let signIn: @Sendable (String, String) async throws -> AccountAuthResult
    public let signOut: @Sendable () throws -> Void
    public let makeListener: @Sendable () -> AccountListenerStream
    public let reauthenticateWithApple: @Sendable (_ signInWithAppleResult: SignInWithAppleResult) async throws -> Void
    public let revokeAppleToken: @Sendable (_ authorizationCode: String) async throws -> Void
    public let deleteAccount: @Sendable () async throws -> Void

    public init(
        signIn: @Sendable @escaping (String, String) async throws -> AccountAuthResult = { _, _ in .init(id: "id") },
        signOut: @Sendable @escaping () throws -> Void = {},
        makeListener: @Sendable @escaping () -> AccountListenerStream = {

            let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
            return AccountListenerStream(values: stream,
                                         listenerToken: NSObject(),
                                         continuation: continuation)
        },
        reauthenticateWithApple: @Sendable @escaping (_: SignInWithAppleResult) async throws -> Void = { _ in },
        revokeAppleToken: @Sendable @escaping (_: String) async throws -> Void = { _ in },
        deleteAccount: @Sendable @escaping () async throws -> Void = {}
    ) {

        self.signIn = signIn
        self.signOut = signOut
        self.makeListener = makeListener
        self.reauthenticateWithApple = reauthenticateWithApple
        self.revokeAppleToken = revokeAppleToken
        self.deleteAccount = deleteAccount
    }
}

public extension AccountAuthClient {
    static let previewValue = AccountAuthClient()
}
