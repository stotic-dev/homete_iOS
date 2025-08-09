//
//  DomainError.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import SwiftUI

enum DomainError: Error, Equatable {
    
    case noNetwork
    case failAuth
    case other
    
    var message: LocalizedStringKey {
        
        switch self {
            
        case .noNetwork:
            return "通信に失敗しました"
            
        case .failAuth:
            return "認証に失敗しました。再度サインインをお試しください。"
            
        case .other:
            return "不明のエラーが発生しました"
        }
    }
}

extension DomainError {
    
    static func make(_ error: (any Error)?) -> Self? {
        
        guard let error else { return nil }
        return error as? DomainError ?? .other
    }
}
