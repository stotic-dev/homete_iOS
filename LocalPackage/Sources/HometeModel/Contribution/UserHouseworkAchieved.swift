//
//  UserHouseworkAchieved.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

public struct UserHouseworkAchieved: Hashable, Identifiable, Sendable {

    public let userId: String
    public let userName: String
    /// 達成した家事の数
    public let achievedCount: Int

    public init(
        userId: String,
        userName: String,
        achievedCount: Int
    ) {
        self.userId = userId
        self.userName = userName
        self.achievedCount = achievedCount
    }

    public var id: String {
        userId
    }

}
