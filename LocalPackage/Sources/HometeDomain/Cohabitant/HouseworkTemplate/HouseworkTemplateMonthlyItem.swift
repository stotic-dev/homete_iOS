//
//  HouseworkTemplateMonthlyItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation

/// 毎月繰り返すテンプレートの家事
///
/// 毎週の家事（`HouseworkTemplateDay.items`）と違い、1家事が1ドキュメントで、繰り返しルールを家事自身が持つ（ADR-0021）。
public struct HouseworkTemplateMonthlyItem: Identifiable, Sendable, Equatable, Hashable {

    public let item: HouseworkTemplateItem
    public let rule: MonthlyRecurrenceRule

    public var id: HouseworkTemplateItem.ItemId {
        item.id
    }

    public init(item: HouseworkTemplateItem, rule: MonthlyRecurrenceRule) {
        self.item = item
        self.rule = rule
    }

}

// MARK: - Codable

/// Firestore上では家事の項目とルールを1階層に並べ、`id`はドキュメントIDと同じ文字列で保存する（ADR-0021）
extension HouseworkTemplateMonthlyItem: Codable {

    private enum CodingKeys: String, CodingKey {

        case id
        case title
        case point
        case updatedAt
        case rule

    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        item = try .init(
            id: .init(id: container.decode(String.self, forKey: .id)),
            title: container.decode(String.self, forKey: .title),
            point: container.decode(Int.self, forKey: .point),
            updatedAt: container.decode(Date.self, forKey: .updatedAt)
        )
        rule = try container.decode(MonthlyRecurrenceRule.self, forKey: .rule)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(item.id.id, forKey: .id)
        try container.encode(item.title, forKey: .title)
        try container.encode(item.point, forKey: .point)
        try container.encode(item.updatedAt, forKey: .updatedAt)
        try container.encode(rule, forKey: .rule)
    }

}
