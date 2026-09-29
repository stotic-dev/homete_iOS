//
//  FrequentHouseworkEditTarget.swift
//  LocalPackage
//

import HometeDomain

/// 追加・編集モーダルで扱う対象
enum FrequentHouseworkEditTarget: Identifiable, Equatable {

    /// 新しく追加する
    case create
    /// 既存の家事を編集する
    case edit(FrequentHouseworkItem)

    var id: String {
        switch self {
        case .create:
            "create"

        case let .edit(item):
            item.id
        }
    }

}
