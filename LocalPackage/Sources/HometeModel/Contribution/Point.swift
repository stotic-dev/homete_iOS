//
//  Point.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

/// ポイントを表すモデル
public struct Point: Equatable, Hashable, Sendable {

    public let value: Int

    public init(
        value: Int
    ) {
        self.value = value
    }

}
