//
//  AnalyticsEvent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

struct AnalyticsEvent: Equatable {
    
    let name: String
    let parameters: [String: String]
}

extension AnalyticsEvent {
    
    static func login(isSuccess: Bool) -> Self {
        
        return .init(
            name: "login",
            parameters: ["isSuccess": "\(isSuccess)"]
        )
    }
    
    static func logout() -> Self {
        
        return .init(
            name: "logout",
            parameters: [:]
        )
    }
    
    static func deleteAccount() -> Self {
        
        return .init(
            name: "delete_account",
            parameters: [:]
        )
    }
}
