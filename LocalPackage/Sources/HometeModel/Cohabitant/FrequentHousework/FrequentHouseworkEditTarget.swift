//
//  FrequentHouseworkEditTarget.swift
//  LocalPackage
//


/// 追加・編集モーダルで扱う対象
public enum FrequentHouseworkEditTarget: Identifiable, Equatable, Sendable {

    /// 新しく追加する
    case create
    /// 既存の家事を編集する
    case edit(FrequentHouseworkItem)

    public var id: String {
        switch self {
        case .create:
            "create"

        case let .edit(item):
            item.id
        }
    }

}
