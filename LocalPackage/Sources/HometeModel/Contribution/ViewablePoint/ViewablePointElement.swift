//
//  ViewablePointElement.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

public struct ViewablePointElement: Equatable, Hashable, Sendable {

    public let point: Point
    public let date: Date

    public init(
        point: Point,
        date: Date
    ) {
        self.point = point
        self.date = date
    }

}
