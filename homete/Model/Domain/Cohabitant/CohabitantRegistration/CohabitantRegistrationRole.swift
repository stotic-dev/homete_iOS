//
//  CohabitantRegistrationRole.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

enum CohabitantRegistrationRole: Codable, Equatable {
    
    /// フォロワーはアカウントIDを渡す
    case follower(accountId: String)
    case lead
    
    var isLeader: Bool {
        
        return self == .lead
    }
    
    var accountId: String {
        
        guard case let .follower(accountId) = self else {
            
            preconditionFailure("Please pre checking role is follower.")
        }
        return accountId
    }
}
