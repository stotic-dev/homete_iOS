//
//  HouseworkState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

enum HouseworkState: CaseIterable, Identifiable, Codable, Sendable {
    
    case incomplete
    case pendingApproval
    case completed
    
    var id: Self { self }
}
