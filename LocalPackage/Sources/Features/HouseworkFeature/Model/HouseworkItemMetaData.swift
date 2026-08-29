//
//  HouseworkItemMetaData.swift
//  homete
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事セルに添えて表示する、その家事が今どういう状況にあるかを示すメタデータ
///
/// 家事名とポイントだけでは「自分が承認依頼を出したもの」なのか「自分が承認する必要があるもの」なのかを
/// 区別できず、セルを見ただけではその家事に対して行えるアクションが分からない。状況をラベルで補う。
enum HouseworkItemMetaData: Equatable, CaseIterable {

    /// 相手が実施済みで、自分の確認を待っている
    case needsOwnReview
    /// 自分が実施済みで、相手の確認を待っている
    case waitingForOtherReview
    /// 確認済みで完了している
    case completed
    /// やらないことにした
    case notTodo

    var label: String {
        switch self {
        case .needsOwnReview:
            "要確認"
        case .waitingForOtherReview:
            "相手の確認待ち"
        case .completed:
            "完了"
        case .notTodo:
            "やらない"
        }
    }

    var systemImage: String {
        switch self {
        case .needsOwnReview:
            "exclamationmark.bubble.fill"
        case .waitingForOtherReview:
            "hourglass"
        case .completed:
            "checkmark.seal.fill"
        case .notTodo:
            "minus.circle"
        }
    }

    /// 自分が対応する必要のあるものだけをアクセントカラーで目立たせる
    var foregroundStyle: Color {
        switch self {
        case .needsOwnReview:
            .primary1
        case .waitingForOtherReview, .completed, .notTodo:
            .onSubSurface
        }
    }

}

extension HouseworkItemMetaData {

    /// 家事の状態と実施者から、セルに表示するメタデータを決める
    ///
    /// 未着手（`incomplete`）は誰も実施していないため補う情報がなく、`nil`を返す。
    static func make(item: HouseworkItem, ownUserId: String) -> Self? {
        switch item.state {
        case .incomplete:
            nil

        case .pendingApproval:
            item.executorId == ownUserId ? .waitingForOtherReview : .needsOwnReview

        case .completed:
            .completed

        case .notTodo:
            .notTodo
        }
    }

}
