//
//  NewHouseworkEntry.swift
//  LocalPackage
//

/// まとめて登録する家事1件
/// - Note: 入力元は家事のデータには残さず、Analyticsの`source`にだけ使う
public struct NewHouseworkEntry: Equatable, Sendable {

    public let item: HouseworkItem
    public let source: HouseworkRegisterSource

    public init(item: HouseworkItem, source: HouseworkRegisterSource) {
        self.item = item
        self.source = source
    }

}
