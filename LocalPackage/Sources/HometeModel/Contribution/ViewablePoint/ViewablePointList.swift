//
//  ViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

public struct ViewablePointList: Equatable, Hashable, Sendable {

    /// ユーザーID
    public let userId: String
    /// ユーザー名
    public let userName: String
    /// トータルのポイント
    public let total: Point
    /// 表示するポイントのリスト
    public let elements: Set<ViewablePointElement>

    public init(
        userId: String,
        userName: String,
        total: Point,
        elements: Set<ViewablePointElement>
    ) {
        self.userId = userId
        self.userName = userName
        self.total = total
        self.elements = elements
    }

    public var sortedElements: [ViewablePointElement] {
        elements.sorted { $0.date < $1.date }
    }

}

/// ViewablePointListを生成するインターフェース
public protocol GenerableViewablePointList {

    func generate() -> ViewablePointList

}
