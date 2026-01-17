//
//  CohabitantData.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

struct CohabitantData: Codable {
    
    static let idField = "id"
    
    /// 家族グループのID
    let id: String
    /// 参加しているメンバーのユーザーID
    let members: [String]
}
