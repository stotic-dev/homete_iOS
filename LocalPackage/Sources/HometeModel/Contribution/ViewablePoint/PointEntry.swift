//
//  PointEntry.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/07.
//

public struct PointEntry: Identifiable, Equatable, Sendable {

    public let id: String
    public let userName: String
    public let point: Int

    public init(
        id: String,
        userName: String,
        point: Int
    ) {
        self.id = id
        self.userName = userName
        self.point = point
    }

}
