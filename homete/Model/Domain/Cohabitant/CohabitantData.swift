//
//  CohabitantData.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

struct CohabitantData: Codable {
    
    static let idField = "id"
    
    let id: String
    let members: [String]
}
