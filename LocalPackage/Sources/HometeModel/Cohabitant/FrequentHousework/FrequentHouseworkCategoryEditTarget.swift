//
//  FrequentHouseworkCategoryEditTarget.swift
//  LocalPackage
//

import Foundation

/// カテゴリの名前を入力するアラートの対象
/// - Note: 追加と名前の変更は入力する内容が同じなので、1つのアラートで扱う
public enum FrequentHouseworkCategoryEditTarget: Equatable, Sendable {

    case create
    case rename(FrequentHouseworkCustomCategory)

    public var title: LocalizedStringResource {
        switch self {
        case .create:
            .localized("カテゴリを追加")

        case .rename:
            .localized("カテゴリの名前を変更")
        }
    }

    public var confirmLabel: LocalizedStringResource {
        switch self {
        case .create:
            .localized("追加")

        case .rename:
            .localized("変更")
        }
    }

    /// アラートを開いたときに入れておく名前
    public var initialName: String {
        switch self {
        case .create:
            ""

        case let .rename(category):
            category.name
        }
    }

    /// 名前の重複の判定から外すカテゴリID。追加のときは`nil`
    public var editingId: String? {
        switch self {
        case .create:
            nil

        case let .rename(category):
            category.id
        }
    }

}
