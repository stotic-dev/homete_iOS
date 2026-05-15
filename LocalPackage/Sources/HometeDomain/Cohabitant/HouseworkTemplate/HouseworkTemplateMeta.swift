public struct HouseworkTemplateMeta: Identifiable, Codable, Sendable, Equatable {

    public let templateId: String
    public let name: String

    public var id: String {
        templateId
    }

    public init(templateId: String, name: String) {
        self.templateId = templateId
        self.name = name
    }

}
