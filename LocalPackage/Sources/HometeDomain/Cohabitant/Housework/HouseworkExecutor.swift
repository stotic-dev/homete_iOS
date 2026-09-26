//
//  HouseworkExecutor.swift
//  LocalPackage
//

/// 家事の担当者と、その人に配分した割合・ポイント
///
/// 割合からポイントへの換算は保存時に一度だけ行う（ADR-0022）。集計は`point`を足すだけにする。
public struct HouseworkExecutor: Codable, Equatable, Hashable, Sendable {

    /// 担当者のユーザーID
    public let userId: String
    /// 画面に出す割合。担当者全員の合計が100
    public let percentage: Int
    /// 集計に使うポイント。担当者全員の合計が家事のポイントと一致し、1以上
    public let point: Int

    public init(userId: String, percentage: Int, point: Int) {
        self.userId = userId
        self.percentage = percentage
        self.point = point
    }

}

public extension HouseworkExecutor {

    /// 1人で担当した（ポイントを満額配分した）担当者
    static func solo(userId: String, point: Int) -> Self {
        .init(userId: userId, percentage: 100, point: point)
    }

}
