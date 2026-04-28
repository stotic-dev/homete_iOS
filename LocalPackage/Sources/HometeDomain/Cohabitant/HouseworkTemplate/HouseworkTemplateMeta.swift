public struct HouseworkTemplateMeta: Identifiable, Codable, Sendable, Equatable {
    public let templateId: String
    public let name: String
    /// 楽観的ロック用バージョン
    public let version: Int

    public var id: String { templateId }

    public init(templateId: String, name: String, version: Int) {
        self.templateId = templateId
        self.name = name
        self.version = version
    }
}
