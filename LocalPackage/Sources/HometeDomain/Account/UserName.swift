//
//  UserName.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

public struct UserName {
    public var value = ""

    private static let limitCharacters = 10

    public var remainingCharacters: Int {
        return Self.limitCharacters - value.count
    }

    public var isOverLimitCharacters: Bool {
        return Self.limitCharacters < value.count
    }

    public var canRegistration: Bool {
        return !value.isEmpty && !isOverLimitCharacters
    }

    public init(value: String = "") {
        self.value = value
    }
}
