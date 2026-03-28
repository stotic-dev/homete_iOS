//
//  HouseworkState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

public enum HouseworkState: CaseIterable, Identifiable, Codable, Sendable {

    case incomplete
    case pendingApproval
    case completed

    public var id: Self { self }
}
