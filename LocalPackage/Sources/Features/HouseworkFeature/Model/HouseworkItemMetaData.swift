//
//  HouseworkItemMetaData.swift
//  homete
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事セルに添えて表示する、その家事が今どういう状況にあるかを示すメタデータ
///
/// 家事名とポイントだけでは、その家事がもう済んでいるのか、やらないことにしたのかが分からない。
/// 状況をラベルで補う。
enum HouseworkItemMetaData: Equatable, CaseIterable {

    /// 完了している
    case completed
    /// やらないことにした
    case notTodo

    var label: String {
        switch self {
        case .completed:
            "完了"
        case .notTodo:
            "やらない"
        }
    }

    var systemImage: String {
        switch self {
        case .completed:
            "checkmark.seal.fill"
        case .notTodo:
            "minus.circle"
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .completed, .notTodo:
            .onSubSurface
        }
    }

}

extension HouseworkItemMetaData {

    /// 家事の状態から、セルに表示するメタデータを決める
    ///
    /// 未着手（`incomplete`）は誰も実施していないため補う情報がなく、`nil`を返す。
    static func make(item: HouseworkItem) -> Self? {
        switch item.state {
        case .incomplete:
            nil

        case .completed:
            .completed

        case .notTodo:
            .notTodo
        }
    }

}
