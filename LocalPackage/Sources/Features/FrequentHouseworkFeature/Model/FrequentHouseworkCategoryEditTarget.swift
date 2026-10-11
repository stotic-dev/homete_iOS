//
//  FrequentHouseworkCategoryEditTarget.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// カテゴリの名前を入力するアラートの対象
/// - Note: 追加と名前の変更は入力する内容が同じなので、1つのアラートで扱う
enum FrequentHouseworkCategoryEditTarget: Equatable {

    case create
    case rename(FrequentHouseworkCustomCategory)

    var title: LocalizedStringResource {
        switch self {
        case .create:
            .localized("カテゴリを追加")

        case .rename:
            .localized("カテゴリの名前を変更")
        }
    }

    var confirmLabel: LocalizedStringResource {
        switch self {
        case .create:
            .localized("追加")

        case .rename:
            .localized("変更")
        }
    }

    /// アラートを開いたときに入れておく名前
    var initialName: String {
        switch self {
        case .create:
            ""

        case let .rename(category):
            category.name
        }
    }

    /// 名前の重複の判定から外すカテゴリID。追加のときは`nil`
    var editingId: String? {
        switch self {
        case .create:
            nil

        case let .rename(category):
            category.id
        }
    }

}
