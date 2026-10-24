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
            Auth.auth().currentUser.map { .init(id: $0.uid, isAnonymous: $0.isAnonymous) }
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
        },
        signInAnonymously: {
            let authInfo = try await Auth.auth().signInAnonymously()
            return .init(id: authInfo.user.uid, isAnonymous: authInfo.user.isAnonymous)
        },
        linkWithApple: { tokenId, nonce in
            try await linkWithApple(tokenId: tokenId, nonce: nonce)
        },
        signInWithExistingCredential: { credential in
            guard let credential = credential.rawValue as? AuthCredential else {
                throw DomainError.failAuth
            }
            let authInfo = try await Auth.auth().signIn(with: credential)
            return .init(id: authInfo.user.uid, isAnonymous: authInfo.user.isAnonymous)
        },
        deleteAnonymousAccount: {
            _ = try await FunctionsService.call("deleteanonymousaccount")
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
        return .init(id: authInfo.user.uid, isAnonymous: authInfo.user.isAnonymous)
    }

    static func linkWithApple(tokenId: String, nonce: String) async throws -> AccountAuthResult {
        guard let user = Auth.auth().currentUser else {
            throw DomainError.failAuth
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenId,
            rawNonce: nonce
        )
        do {
            let authInfo = try await user.link(with: credential)
            return .init(id: authInfo.user.uid, isAnonymous: authInfo.user.isAnonymous)
        } catch let error as NSError {
            // Appleの認証情報は1回しか使えないため、別のアカウントで使われていたときは
            // エラーに載ってくる認証情報を返し、それでログインし直してもらう
            guard AuthErrorCode(rawValue: error.code) == .credentialAlreadyInUse,
                  let updatedCredential = error.userInfo[AuthErrors.userInfoUpdatedCredentialKey]
                  as? AuthCredential else {
                throw error
            }
            throw AccountLinkError.credentialAlreadyInUse(.init(rawValue: updatedCredential))
        }
    }

    static func makeListener() -> AccountListenerStream {
        let (stream, continuation) = AsyncStream<AccountAuthResult?>.makeStream()
        let token = Auth.auth().addStateDidChangeListener { _, user in
            guard let user else {
                continuation.yield(nil)
                return
            }

            continuation.yield(.init(id: user.uid, isAnonymous: user.isAnonymous))
        }
        return .init(values: stream, listenerToken: token, continuation: continuation)
    }

}
