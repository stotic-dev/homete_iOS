//
//  DomainError.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

enum DomainError: Error, Equatable {
    
    case failAuth
    case noNetwork
    case other
}

extension DomainError {
    
    static func make(_ error: (any Error)?) -> Self? {
        
        guard let error else { return nil }
        return error as? DomainError ?? .other
    }
}
