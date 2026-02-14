//
//  AccountAuthResult.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AccountAuthResult: Equatable, Sendable {

    public let id: String

    public init(id: String) {
        self.id = id
    }
}
