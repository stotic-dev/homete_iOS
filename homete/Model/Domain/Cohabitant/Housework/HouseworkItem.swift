//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

struct HouseworkItem: Identifiable, Equatable, Codable {
    
    let id: String
    let title: String
    let point: Int
    let state: HouseworkState
}
