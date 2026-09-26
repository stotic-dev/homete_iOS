//
//  HouseworkBoardEmptyReason.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import HometeDomain

/// 家事ボードの各タブが空のときの理由
enum HouseworkBoardEmptyReason: Equatable {

    /// 家事が1件も登録されていない
    case noHouseworkRegistered
    /// 未完了タブ: 全ての家事が完了またはやらないに移行済み
    case allCompleted
    /// 完了タブ: 完了した家事がまだない
    case hasIncompleteHousework

    /// 指定された状態のタブが空のときの理由を返す。表示対象の家事がある場合は `nil`。
    init?(list: HouseworkBoardList, state: HouseworkState) {
        guard list.items(matching: state).isEmpty else { return nil }

        if list.items.isEmpty {
            self = .noHouseworkRegistered
            return
        }

        switch state {
        case .incomplete:
            self = .allCompleted

        case .completed, .notTodo:
            self = .hasIncompleteHousework
        }
    }

}
