//
//  DependencyClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/04.
//

protocol DependencyClient: Sendable {
    static var liveValue: Self { get }
}
