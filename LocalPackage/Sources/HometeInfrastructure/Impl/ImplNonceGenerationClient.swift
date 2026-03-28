//
//  ImplNonceGenerationClient.swift
//

import CryptoKit
import Foundation
import HometeDomain

extension NonceGenerationClient {

    static let liveValue: NonceGenerationClient = .init {

        var randomBytes = [UInt8](repeating: 0, count: 32)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {

          fatalError(
            "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
          )
        }

        let charset: [Character] =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in

          // Pick a random character from the set, wrapping around if needed.
          charset[Int(byte) % charset.count]
        }

        return .init(original: String(nonce), sha256: Self.sha256(String(nonce)))
    }

    private static func sha256(_ input: String) -> String {

      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
      return hashString
    }
}
