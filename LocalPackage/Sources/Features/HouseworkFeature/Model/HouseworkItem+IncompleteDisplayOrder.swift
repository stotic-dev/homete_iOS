//
//  HouseworkItem+IncompleteDisplayOrder.swift
//  LocalPackage
//

import HometeDomain

extension HouseworkItem {

    /// 未完了家事の表示順（ポイント降順）を決める比較関数
    ///
    /// Firestoreの取得順は安定しないため、表示のたびに並び順が変わっていた。
    /// ポイントの高い家事から並べ、取りかかる価値の大きいものをファーストビューに出す。
    static func isIncompleteDisplayOrderedBefore(_ lhs: HouseworkItem, _ rhs: HouseworkItem) -> Bool {
        if lhs.point != rhs.point {
            return lhs.point > rhs.point
        }
        return lhs.id < rhs.id
    }

}
