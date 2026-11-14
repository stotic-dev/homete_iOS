//
//  HouseworkItemMetaData.swift
//  homete
//

/// 家事セルに添えて表示する、その家事が今どういう状況にあるかを示すメタデータ
///
/// 家事名とポイントだけでは、その家事がもう済んでいるのか、やらないことにしたのかが分からない。
/// 状況をラベルで補う。
public enum HouseworkItemMetaData: Equatable, CaseIterable, Sendable {

    /// 完了している
    case completed
    /// やらないことにした
    case notTodo

}

public extension HouseworkItemMetaData {

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
