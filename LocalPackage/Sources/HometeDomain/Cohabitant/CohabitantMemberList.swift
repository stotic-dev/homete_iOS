//
//  CohabitantMemberList.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantMemberList {

    public private(set) var value: Set<CohabitantMember>

    public init(value: Set<CohabitantMember>) {
        self.value = value
    }

    public mutating func insert(_ element: CohabitantMember) {

        value.insert(element)
    }

    /// 与えられたユーザーID配列の中から、まだvalueに存在しないユーザーIDのみを返します。
    /// - Parameter userIds: 追加するユーザーIDの候補の配列
    /// - Returns: 追加が必要なユーザーIDの配列
    public func missingMemberIds(from userIds: Set<String>) -> Set<String> {

        let existingIds = value.map(\.id)
        return userIds.filter { !existingIds.contains($0) }
    }

    /// 現在の家族グループの中から指定のユーザーIDの名前を取得する
    /// - Parameter id: ユーザーID
    /// - Returns: ユーザー名
    public func userName(_ id: String) -> String? {

        return value.first { $0.id == id }?.userName
    }
}
