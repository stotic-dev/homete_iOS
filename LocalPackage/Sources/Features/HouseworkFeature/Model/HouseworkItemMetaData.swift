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
    /// 完了していて、ありがとうが届いている
    case thanked
    /// やらないことにした
    case notTodo

    var label: String {
        switch self {
        case .completed:
            "完了"
        case .thanked:
            "ありがとうが届いています"
        case .notTodo:
            "やらない"
        }
    }

    var systemImage: String {
        switch self {
        case .completed:
            "checkmark.seal.fill"
        case .thanked:
            "hands.clap.fill"
        case .notTodo:
            "minus.circle"
        }
    }

    /// ありがとうが届いたことを、ひと目で気づけるようアクセントカラーで目立たせる
    var foregroundStyle: Color {
        switch self {
        case .thanked:
            .primary1
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
            item.thanks.isEmpty ? .completed : .thanked

        case .notTodo:
            .notTodo
        }
    }

}
