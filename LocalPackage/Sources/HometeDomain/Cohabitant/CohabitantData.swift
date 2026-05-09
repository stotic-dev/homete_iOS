//
//  CohabitantData.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantData: Codable, Sendable {

    public static let idField = "id"

    private enum CodingKeys: String, CodingKey {
        case id
        case members
        case appliedTemplates
    }

    /// 家族グループのID
    public let id: String
    /// 参加しているメンバーのユーザーID
    public let members: [String]
    /// テンプレート適用履歴 (key: templateId)
    public let appliedTemplates: [String: AppliedTemplateRecord]

    public init(id: String, members: [String], appliedTemplates: [String: AppliedTemplateRecord] = [:]) {
        self.id = id
        self.members = members
        self.appliedTemplates = appliedTemplates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        members = try container.decode([String].self, forKey: .members)
        appliedTemplates = try container.decodeIfPresent(
            [String: AppliedTemplateRecord].self,
            forKey: .appliedTemplates
        ) ?? [:]
    }
}
