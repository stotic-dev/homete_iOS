import Foundation

public struct HouseworkTemplateItem: Identifiable, Codable, Sendable, Equatable, Hashable {

    public let id: ItemId
    public let title: String
    public let point: Int
    public let updatedAt: Date
    /// テンプレートから作る家事に引き継ぐメモ
    public let memo: HouseworkMemo?

    public init(id: ItemId, title: String, point: Int, updatedAt: Date, memo: HouseworkMemo? = nil) {
        self.id = id
        self.title = title
        self.point = point
        self.updatedAt = updatedAt
        self.memo = memo
    }

}

public extension HouseworkTemplateItem {

    struct ItemId: Codable, Sendable, Equatable, Hashable {

        public let id: String

        public init(id: String) {
            self.id = id
        }

    }

}

public extension HouseworkTemplateItem.ItemId {

    init(uuid: UUID) {
        self.init(id: uuid.uuidString)
    }

}
