/// CohabitantData.appliedTemplates の値型。テンプレートの適用履歴を保持する。
public struct AppliedTemplateRecord: Codable, Sendable, Equatable {
    /// ISO週番号形式 (例: "2026-W17")
    public let lastAppliedWeek: String
    public let lastAppliedVersion: Int

    public init(lastAppliedWeek: String, lastAppliedVersion: Int) {
        self.lastAppliedWeek = lastAppliedWeek
        self.lastAppliedVersion = lastAppliedVersion
    }
}
