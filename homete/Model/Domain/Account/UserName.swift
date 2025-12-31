//
//  UserName.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

struct UserName {
    var value = ""
    
    private static let limitCharacters = 10
    
    var remainingCharacters: Int {
        return Self.limitCharacters - value.count
    }
    
    var isOverLimitCharacters: Bool {
        return Self.limitCharacters < value.count
    }
    
    var canRegistration: Bool {
        return !value.isEmpty && !isOverLimitCharacters
    }
}
