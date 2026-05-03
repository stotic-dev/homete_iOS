//
//  CohabitantMemberList.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantMemberList: Sendable, Equatable {

    private var _value: Set<CohabitantMember>
    let ownId: String
    
    public var value: [CohabitantMember] {
        
        guard let own = _value.first(where: { $0.id == ownId }) else { return [] }
        return [own] + .init(_value)
            .filter { $0.id != ownId }
            .sorted { $0.id < $1.id }
    }

    public init(value: Set<CohabitantMember>, ownId: String) {
        _value = value
        self.ownId = ownId
    }

    public mutating func insert(_ element: CohabitantMember) {

        _value.insert(element)
    }

    /// 与えられたユーザーID配列の中から、まだvalueに存在しないユーザーIDのみを返します。
    /// - Parameter userIds: 追加するユーザーIDの候補の配列
    /// - Returns: 追加が必要なユーザーIDの配列
    public func missingMemberIds(from userIds: Set<String>) -> Set<String> {

        let existingIds = _value.map(\.id)
        return userIds.filter { !existingIds.contains($0) }
    }

    /// 現在の家族グループの中から指定のユーザーIDの名前を取得する
    /// - Parameter id: ユーザーID
    /// - Returns: ユーザー名
    public func userName(_ id: String) -> String? {

        return _value.first { $0.id == id }?.userName
    }
}
