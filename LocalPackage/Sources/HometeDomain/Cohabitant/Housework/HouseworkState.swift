//
//  HouseworkState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

public enum HouseworkState: CaseIterable, Identifiable, Codable, Sendable {

    /// 未完了
    case incomplete
    /// 承認待ち
    case pendingApproval
    /// 完了
    case completed
    /// やらない
    case notTodo

    public var id: Self {
        self
    }

}
