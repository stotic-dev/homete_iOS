//
//  FrequentHouseworkCategoryEditTarget.swift
//  LocalPackage
//

import HometeDomain

/// カテゴリの名前を入力するアラートの対象
/// - Note: 追加と名前の変更は入力する内容が同じなので、1つのアラートで扱う
enum FrequentHouseworkCategoryEditTarget: Equatable {

    case create
    case rename(FrequentHouseworkCustomCategory)

    var title: String {
        switch self {
        case .create:
            "カテゴリを追加"

        case .rename:
            "カテゴリの名前を変更"
        }
    }

    var confirmLabel: String {
        switch self {
        case .create:
            "追加"

        case .rename:
            "変更"
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
