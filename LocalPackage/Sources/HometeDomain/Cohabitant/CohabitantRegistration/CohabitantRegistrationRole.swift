//
//  CohabitantRegistrationRole.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

public enum CohabitantRegistrationRole: Codable, Equatable, Sendable {

    case follower
    case lead

    public var isLeader: Bool {
        self == .lead
    }

}
