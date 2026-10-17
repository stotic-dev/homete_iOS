//
//  ImplAccountAuthClient.swift
//

import FirebaseAuth
import HometeDomain
import HometeInfrastructure

extension AccountAuthClient {

    static let liveValue: AccountAuthClient = .init(
        signIn: { tokenId, nonce in
            try await signInWithApple(tokenId: tokenId, nonce: nonce)
        },
        signOut: {
            try Auth.auth().signOut()
        },
        makeListener: {
            Self.makeListener()
        },
        currentAuth: {
            // Firebase Authは初期化時に保存済みのユーザーの読み込みを内部のキューに積み、currentUserは同じキューで待って読む。
            // そのため起動直後でも読み込みを終えた値が返る。リスナーの初回の呼び出しはキューを待たずに読むため、こちらを使う
            Auth.auth().currentUser.map { .init(id: $0.uid) }
        },
        reauthenticateWithApple: { signInWithAppleResult in
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: signInWithAppleResult.tokenId,
                rawNonce: signInWithAppleResult.nonce
            )
            guard let user = Auth.auth().currentUser else {
                throw DomainError.failAuth
            }
            try await user.reauthenticate(with: credential)
        },
        revokeAppleToken: { authorizationCode in
            try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
        },
        deleteAccount: {
            guard let user = Auth.auth().currentUser else {
                throw DomainError.failAuth
            }
            try await user.delete()
        }
    )

}

private extension AccountAuthClient {

    static func signInWithApple(tokenId: String, nonce: String) async throws -> AccountAuthResult {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenId,
            rawNonce: nonce
        )
        let authInfo = try await Auth.auth().signIn(with: credential)
        return .init(id: authInfo.user.uid)
    }

    static func makeListener() -> AccountListenerStream {
        let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
        let token = Auth.auth().addStateDidChangeListener { _, user in
            guard let user else {
                continuation.yield(nil)
                return
            }

            continuation.yield(.init(id: user.uid))
        }
        return .init(values: stream, listenerToken: token, continuation: continuation)
    }

}
