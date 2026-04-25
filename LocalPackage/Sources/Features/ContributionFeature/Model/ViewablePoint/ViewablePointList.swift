//
//  ViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

protocol ViewablePointList<Element>: Equatable, Hashable {
    
    associatedtype Element: ViewablePointElement
    
    /// ユーザーID 
    var userId: String { get }
    /// 表示区間
    var displayPeriod: DisplayPointPeriod { get }
    /// トータルのポイント
    var total: Point { get }
    /// 表示するポイントのリスト
    var elements: Set<Element> { get }
}
