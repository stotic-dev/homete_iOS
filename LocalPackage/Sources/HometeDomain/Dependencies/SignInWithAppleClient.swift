//
//  SignInWithAppleClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

public struct SignInWithAppleClient: Sendable {
    public let reauthentication: @MainActor (_ nonce: SignInWithAppleNonce) async throws -> SignInWithAppleResult

    public init(
        reauthentication: @MainActor @escaping (_ nonce: SignInWithAppleNonce)
        async throws -> SignInWithAppleResult = { _ in preconditionFailure() }
    ) {

        self.reauthentication = reauthentication
    }
}

public extension SignInWithAppleClient {

    static let previewValue = SignInWithAppleClient()
}
