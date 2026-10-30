//
//  PresetFrequentHouseworkCategory.swift
//  LocalPackage
//

import Foundation

/// あらかじめ用意しているカテゴリ
/// - Note: Firestoreには持たず、アプリ内の定数とする。名前の変更・削除はできない。
///         `allCases`の順がそのまま表示順になる
public enum PresetFrequentHouseworkCategory: String, CaseIterable, Sendable, Hashable {

    case cleaning = "preset.cleaning"
    case laundry = "preset.laundry"
    case cooking = "preset.cooking"
    case shopping = "preset.shopping"
    case garbage = "preset.garbage"

    public var name: LocalizedStringResource {
        switch self {
        case .cleaning: .localized("掃除", comment: "家事のカテゴリ名")
        case .laundry: .localized("洗濯", comment: "家事のカテゴリ名")
        case .cooking: .localized("料理", comment: "家事のカテゴリ名")
        case .shopping: .localized("買い物", comment: "家事のカテゴリ名")
        case .garbage: .localized("ゴミ", comment: "家事のカテゴリ名")
        }
    }

}
