//
//  FrequentHouseworkCategory.swift
//  LocalPackage
//

/// 画面に表示するカテゴリ
public enum FrequentHouseworkCategory: Identifiable, Sendable, Hashable {

    case preset(PresetFrequentHouseworkCategory)
    case custom(FrequentHouseworkCustomCategory)
    /// 「その他」
    /// - Note: データとしては持たない、表示するときだけの区分。
    ///         カテゴリ未設定の家事と、削除済みのカテゴリを指している家事をまとめる
    case uncategorized

    public var id: String {
        switch self {
        case let .preset(preset): preset.rawValue
        case let .custom(custom): custom.id
        case .uncategorized: "uncategorized"
        }
    }

    public var name: String {
        switch self {
        case let .preset(preset): preset.name
        case let .custom(custom): custom.name
        case .uncategorized: Self.uncategorizedName
        }
    }

    /// 家事に保存するカテゴリID。「その他」は`nil`
    public var categoryId: String? {
        switch self {
        case let .preset(preset): preset.rawValue
        case let .custom(custom): custom.id
        case .uncategorized: nil
        }
    }

    /// 「その他」の表示名
    public static let uncategorizedName = "その他"

}
