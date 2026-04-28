public struct HouseworkTemplateDay: Codable, Sendable, Equatable, Hashable {
    /// 曜日 (0=日曜, 6=土曜)
    public let dayOfWeek: Int
    public let items: [HouseworkTemplateItem]

    public init(dayOfWeek: Int, items: [HouseworkTemplateItem]) {
        self.dayOfWeek = dayOfWeek
        self.items = items
    }
}
