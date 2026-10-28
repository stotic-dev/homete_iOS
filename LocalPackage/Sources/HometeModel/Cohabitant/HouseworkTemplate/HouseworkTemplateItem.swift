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

    /// メモが上限を超えていないか検査する
    /// - Parameter original: 保存前の同じ家事。新しく追加する場合は`nil`
    /// - Throws: 上限を超えている場合は`HouseworkMemoError.limitExceeded`
    public func validateMemo(
        comparedTo original: HouseworkTemplateItem?,
        limitPolicy: HouseworkMemoLimitPolicy
    ) throws {
        try limitPolicy.validate(memo, original: original?.memo)
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
