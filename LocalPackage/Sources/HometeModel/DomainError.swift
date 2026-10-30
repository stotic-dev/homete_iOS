//
//  DomainError.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public enum DomainError: Error, Equatable, Sendable {

    case failAuth
    case noNetwork
    /// ログイン中にFirestore上のアカウントが見つからない（サーバ側で消えているなど）
    case accountNotFound
    case other

}

public extension DomainError {

    static func make(_ error: (any Error)?) -> Self? {
        guard let error else { return nil }
        return error as? DomainError ?? .other
    }

}
