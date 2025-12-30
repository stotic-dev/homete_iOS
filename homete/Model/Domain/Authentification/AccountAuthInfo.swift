//
//  AccountAuthInfo.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

struct AccountAuthInfo: Equatable {
    let result: AccountAuthResult?
    let alreadyLoadedAtInitiate: Bool
    
    static let initial = AccountAuthInfo(result: nil, alreadyLoadedAtInitiate: false)
}
