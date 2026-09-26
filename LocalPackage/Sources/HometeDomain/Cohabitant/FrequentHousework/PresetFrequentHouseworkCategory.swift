//
//  PresetFrequentHouseworkCategory.swift
//  LocalPackage
//

/// あらかじめ用意しているカテゴリ
/// - Note: Firestoreには持たず、アプリ内の定数とする。名前の変更・削除はできない。
///         `allCases`の順がそのまま表示順になる
public enum PresetFrequentHouseworkCategory: String, CaseIterable, Sendable, Hashable {

    case cleaning = "preset.cleaning"
    case laundry = "preset.laundry"
    case cooking = "preset.cooking"
    case shopping = "preset.shopping"
    case garbage = "preset.garbage"

    public var name: String {
        switch self {
        case .cleaning: "掃除"
        case .laundry: "洗濯"
        case .cooking: "料理"
        case .shopping: "買い物"
        case .garbage: "ゴミ"
        }
    }

}
