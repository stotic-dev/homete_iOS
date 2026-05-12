//
//  ViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

struct ViewablePointList: Equatable, Hashable {

    /// ユーザーID
    let userId: String
    /// ユーザー名
    let userName: String
    /// トータルのポイント
    let total: Point
    /// 表示するポイントのリスト
    let elements: Set<ViewablePointElement>

    var sortedElements: [ViewablePointElement] {
        elements.sorted { $0.date < $1.date }
    }

}

/// ViewablePointListを生成するインターフェース
protocol GenerableViewablePointList {

    func generate() -> ViewablePointList

}
