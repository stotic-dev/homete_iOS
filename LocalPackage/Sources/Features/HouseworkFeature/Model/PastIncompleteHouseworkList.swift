//
//  PastIncompleteHouseworkList.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 昨日以前の日付で、まだ終わっていない家事の一覧
///
/// ホームの「やり残している家事」と、家事ボードの日付に付ける印の両方で使い、判定をそろえる。
/// 保存されている家事だけを対象にし、テンプレートから生成されていない過去日の家事は含めない。
/// 期間では絞らず、取得済みの家事（`HouseworkListStore.items`）をすべて対象にする。
public struct PastIncompleteHouseworkList: Equatable, Sendable {

    /// 日付が新しい順（昨日が先頭）の、日ごとの区切り
    ///
    /// プレミアムでさらに前の家事を読み込んだとき、一覧の末尾に足されるよう新しい順にする
    public let sections: [DaySection]

    /// 日付の区切りをいくつ並べるごとに広告を挟むか
    static let advertisementInterval = 3

}

public extension PastIncompleteHouseworkList {

    /// 1日分の、まだ終わっていない家事
    struct DaySection: Equatable, Sendable, Identifiable {

        /// 家事の日付（その日の0時）
        public let date: Date
        /// 未完了の表示順（ポイント降順）に並べた家事
        public let items: [HouseworkBoardItem]

        public var id: Date {
            date
        }

    }

    /// 一覧に並べる要素。日付の区切りと、その間に挟む広告
    enum Element: Equatable, Sendable, Identifiable {

        case section(DaySection)
        /// 何番目の広告か（0始まり）
        case advertisement(index: Int)

        public var id: ElementID {
            switch self {
            case let .section(section): .section(section.date)
            case let .advertisement(index): .advertisement(index)
            }
        }

    }

    enum ElementID: Hashable, Sendable {

        case section(Date)
        case advertisement(Int)

    }

    static func make(storedAllItems: StoredAllHouseworkList, now: Date, calendar: Calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        let sections = storedAllItems.value
            .compactMap { dailyList -> DaySection? in
                let date = calendar.startOfDay(for: dailyList.metaData.indexedDate.value)
                guard date < today else { return nil }

                let items = dailyList.items
                    .filter { $0.state == .incomplete }
                    .sorted(by: HouseworkItem.isIncompleteDisplayOrderedBefore)
                guard !items.isEmpty else { return nil }

                return DaySection(
                    date: date,
                    items: items.map { HouseworkBoardItem(originalItem: $0, isRegistered: true) }
                )
            }
            .sorted { $0.date > $1.date }
        return .init(sections: sections)
    }

    /// まだ終わっていない家事がある日付（その日の0時）
    var dates: Set<Date> {
        Set(sections.map(\.date))
    }

    /// 日付の区切りの間に広告を挟んだ並び
    ///
    /// 区切りを`advertisementInterval`個並べるごとに1つ挟む。一覧の末尾には付けない。
    func elements(showsAdvertisement: Bool) -> [Element] {
        guard showsAdvertisement else { return sections.map { .section($0) } }

        var elements: [Element] = []
        for (offset, section) in sections.enumerated() {
            elements.append(.section(section))
            let count = offset + 1
            if count.isMultiple(of: Self.advertisementInterval), count < sections.count {
                elements.append(.advertisement(index: count / Self.advertisementInterval - 1))
            }
        }
        return elements
    }

}
