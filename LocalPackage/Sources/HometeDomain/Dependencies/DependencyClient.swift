//
//  DependencyClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

public protocol DependencyClient: Sendable {

    static var liveValue: Self { get }
    static var previewValue: Self { get }
}
