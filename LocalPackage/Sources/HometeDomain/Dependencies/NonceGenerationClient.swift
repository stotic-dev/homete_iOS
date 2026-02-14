//
//  NonceGenerationClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import CryptoKit
import Foundation

public struct NonceGenerationClient: Sendable {

    public let value: @Sendable () -> SignInWithAppleNonce
    public func callAsFunction() -> SignInWithAppleNonce {

        return value()
    }

    public init(value: @Sendable @escaping () -> SignInWithAppleNonce) {
        self.value = value
    }
}

public extension NonceGenerationClient {

    static let previewValue: NonceGenerationClient = .init {

        return .init(original: "preview", sha256: "preview sha256")
    }
}
