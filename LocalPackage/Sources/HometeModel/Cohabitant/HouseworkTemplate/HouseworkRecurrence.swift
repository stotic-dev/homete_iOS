//
//  HouseworkRecurrence.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation

/// テンプレートの家事の繰り返し方
public enum HouseworkRecurrence: Sendable, Hashable {

    /// 毎週（指定した曜日）
    case weekly(Set<DayOfWeek>)
    /// 毎月
    case monthly(MonthlyRecurrenceRule)

    /// いつ表示されるかの表示名（「毎日」「毎週月・木」「毎月31日」）
    public var scheduleLabel: LocalizedStringResource {
        switch self {
        case let .weekly(days) where days.count == DayOfWeek.allCases.count:
            .localized("毎日", comment: "家事のくり返し")

        case let .weekly(days):
            .localized(
                "毎週\(Self.daysLabel(days))",
                comment: "家事のくり返し。曜日の名前を並べたものが入る（例: 毎週月曜日・木曜日）"
            )

        case let .monthly(rule):
            rule.label
        }
    }

}

private extension HouseworkRecurrence {

    /// 曜日の名前を、月曜始まりの順に「月曜日・木曜日」のように並べる
    static func daysLabel(_ days: Set<DayOfWeek>) -> String {
        DayOfWeek.displayOrdered
            .filter { days.contains($0) }
            .map { $0.fullLabel.resolved() }
            .joined(separator: LocalizedStringResource.localized("・", comment: "名前を並べるときの区切り（例: Aさん・Bさん、月曜日・木曜日）")
                .resolved())
    }

}
