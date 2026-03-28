//
//  SignInWithAppleResult.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct SignInWithAppleResult: Equatable, Sendable {

    public let tokenId: String
    public let nonce: String
    public let authorizationCode: String

    public init(tokenId: String, nonce: String, authorizationCode: String) {
        self.tokenId = tokenId
        self.nonce = nonce
        self.authorizationCode = authorizationCode
    }
}
