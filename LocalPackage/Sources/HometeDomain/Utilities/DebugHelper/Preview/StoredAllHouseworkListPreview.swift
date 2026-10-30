//
//  StoredAllHouseworkListPreview.swift
//  LocalPackage
//

import Foundation

#if DEBUG

public extension StoredAllHouseworkList {

    /// やり残している家事のプレビュー用に、指定した日数前の日へ未完了の家事を2件ずつ並べる
    /// - Parameter daysAgo: 家事を置く日。今日から何日前か
    static func makeForPastIncompletePreview(today: Date, daysAgo: [Int]) -> Self {
        let calendar = Calendar.japanese
        let titles = ["洗濯", "掃除", "料理", "ゴミ出し", "買い物"]
        let items = daysAgo.enumerated().flatMap { offset, days -> [HouseworkItem] in
            let date = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: today)) ?? today
            return (0 ..< 2).map { index in
                .makeForTest(
                    id: offset * 2 + index,
                    indexedDate: date,
                    title: titles[(offset * 2 + index) % titles.count],
                    point: 10 * (index + 1),
                    expiredAt: .distantFuture
                )
            }
        }
        return .makeMultiDateList(items: items)
    }

}

#endif
