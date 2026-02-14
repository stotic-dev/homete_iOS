//
//  SignInWithAppleNonce.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

public struct SignInWithAppleNonce: Equatable, Sendable {

    public let original: String
    public let sha256: String

    public init(original: String, sha256: String) {
        self.original = original
        self.sha256 = sha256
    }
}
