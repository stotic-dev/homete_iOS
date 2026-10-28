//
//  FrequentHouseworkImportCandidate.swift
//  LocalPackage
//

/// テンプレートから取り込める家事の候補
public struct FrequentHouseworkImportCandidate: Identifiable, Sendable, Equatable {

    public let title: String
    public let point: Int
    /// 同じ名前のいつもの家事がすでにあるか
    public let isAlreadyRegistered: Bool

    /// 候補は名前で重複を除いているため、名前をIDにする
    public var id: String {
        title
    }

    public init(title: String, point: Int, isAlreadyRegistered: Bool) {
        self.title = title
        self.point = point
        self.isAlreadyRegistered = isAlreadyRegistered
    }

}
