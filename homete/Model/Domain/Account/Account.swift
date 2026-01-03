//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

struct Account: Equatable, Codable {
    
    let id: String
    let userName: String
    let fcmToken: String?
    let cohabitantId: String?
}

extension Account {
        
    static func initial(auth: AccountAuthResult, userName: UserName, fcmToken: String?) -> Self {
        
        return .init(id: auth.id, userName: userName.value, fcmToken: fcmToken, cohabitantId: nil)
    }
}
