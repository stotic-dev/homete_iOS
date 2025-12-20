//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

struct Account: Equatable, Codable {
    
    let id: String
    let displayName: String
    let fcmToken: String?
}

extension Account {
    
    static let empty: Self = .init(id: "", displayName: "", fcmToken: nil)
    
    static func initial(_ auth: AccountAuthResult, _ fcmToken: String?) -> Self {
        
        return .init(id: auth.id, displayName: auth.displayName ?? "未設定", fcmToken: fcmToken)
    }
}
