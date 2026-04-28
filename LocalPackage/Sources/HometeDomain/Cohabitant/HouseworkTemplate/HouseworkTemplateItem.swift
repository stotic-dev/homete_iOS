public struct HouseworkTemplateItem: Codable, Sendable, Equatable, Hashable {
    public let title: String
    public let point: Int

    public init(title: String, point: Int) {
        self.title = title
        self.point = point
    }
}
