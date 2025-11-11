//
//  DomainErrorAlertContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/11.
//

import SwiftUI

struct DomainErrorAlertContent {
    
    var isPresenting = false
    let error: DomainError?
    
    var hasError: Bool { error != nil }
    
    var errorMessage: LocalizedStringKey? {
        
        switch error {
            
        case .failAuth:
            return "認証に失敗しました。再度サインインをお試しください。"
            
        case .noNetwork:
            return "通信に失敗しました"
            
        case .other:
            return "不明のエラーが発生しました"
            
        default:
            return nil
        }
    }
    
    static let initial = DomainErrorAlertContent(error: nil)
}

extension DomainErrorAlertContent {
    
    init(error: any Error) {
        
        isPresenting = true
        self.error = .make(error)
    }
}
