//
//  HouseworkExecutorAllocation.swift
//  LocalPackage
//

/// 家事を完了にするときの担当者の選択と、ポイントの配分
///
/// 担当者の並び順は`memberIds`（`CohabitantMemberList.value`の順。自分が先頭）に合わせる。
/// 均等割りの端数と、ポイントへの換算で小数部分が同じだったときの優先順は、どちらもこの順で決める。
public struct HouseworkExecutorAllocation: Equatable, Sendable {

    public struct Entry: Equatable, Sendable {

        public let userId: String
        public let percentage: Int

        public init(userId: String, percentage: Int) {
            self.userId = userId
            self.percentage = percentage
        }

    }

    /// ピッカーで選べる割合（担当者が2人以上のとき）
    public static let percentageRange = 1 ... 99

    /// 選べるメンバーのユーザーID（メンバー一覧の並び順）
    public let memberIds: [String]
    /// 家事のポイント
    public let totalPoint: Int
    /// 選んだ担当者と割合（メンバー一覧の並び順）
    public private(set) var entries: [Entry]

    /// - Parameter selectedIds: 最初に選んでおく担当者。選べる人数の上限を超えた分は先頭から切り詰める
    public init(memberIds: [String], selectedIds: [String], totalPoint: Int) {
        self.memberIds = memberIds
        self.totalPoint = totalPoint
        let orderedIds = memberIds
            .filter { selectedIds.contains($0) }
            .prefix(Self.maxExecutorCount(totalPoint: totalPoint))
        entries = Self.evenEntries(userIds: Array(orderedIds))
    }

}

// MARK: - 担当者の選択

public extension HouseworkExecutorAllocation {

    /// 選べる人数の上限
    ///
    /// 0ptの担当者を許さないため、家事のポイントより多い人数は選べない。
    static func maxExecutorCount(totalPoint: Int) -> Int {
        max(totalPoint, 1)
    }

    func isSelected(_ userId: String) -> Bool {
        entries.contains { $0.userId == userId }
    }

    /// 選択を切り替えられるかどうか
    ///
    /// 選択済みの担当者はいつでも外せる。未選択のメンバーは、人数の上限に達していなければ選べる。
    func canToggle(_ userId: String) -> Bool {
        isSelected(userId) || entries.count < Self.maxExecutorCount(totalPoint: totalPoint)
    }

    /// 担当者の選択を切り替え、均等割りをやり直す
    mutating func toggle(_ userId: String) {
        guard memberIds.contains(userId), canToggle(userId) else { return }

        let selectedIds = isSelected(userId)
            ? entries.map(\.userId).filter { $0 != userId }
            : entries.map(\.userId) + [userId]
        let orderedIds = memberIds.filter { selectedIds.contains($0) }
        entries = Self.evenEntries(userIds: orderedIds)
    }

}

// MARK: - 割合の調整

public extension HouseworkExecutorAllocation {

    /// 割合を調整できるかどうか（担当者が2人以上のとき）
    var canAdjustPercentage: Bool {
        entries.count >= 2
    }

    /// 全員の割合の合計
    var totalPercentage: Int {
        entries.reduce(0) { $0 + $1.percentage }
    }

    /// 担当者の割合を変える
    ///
    /// 2人のときは、もう片方を`100 - percentage`にする。3人以上では、意図しない値に変わらないよう
    /// 他の人の割合は変えない（合計が100%になるまで確定できない）。
    mutating func updatePercentage(_ percentage: Int, for userId: String) {
        guard canAdjustPercentage,
              let index = entries.firstIndex(where: { $0.userId == userId }) else { return }

        let clamped = min(max(percentage, Self.percentageRange.lowerBound), Self.percentageRange.upperBound)
        entries[index] = .init(userId: userId, percentage: clamped)

        if entries.count == 2 {
            let otherIndex = 1 - index
            entries[otherIndex] = .init(userId: entries[otherIndex].userId, percentage: 100 - clamped)
        }
    }

}

// MARK: - ポイントへの換算

public enum HouseworkExecutorAllocationError: Error, Equatable, Sendable {

    /// 担当者が選ばれていない
    case noExecutor
    /// 割合の合計が100%になっていない
    case percentageNotHundred(total: Int)
    /// 0ptになる担当者がいる
    case zeroPoint

}

public extension HouseworkExecutorAllocation {

    /// 担当者ごとのポイント（`entries`と同じ順）。割合の合計が100%でなければ空
    ///
    /// 最大剰余方式で換算する。全員分を切り捨ててから、余ったポイントを小数部分が大きい人から順に
    /// 1ptずつ配る。小数部分が同じなら、メンバー一覧の並び順が早い人を優先する。
    var points: [Int] {
        guard !entries.isEmpty, totalPercentage == 100 else { return [] }

        let products = entries.map { totalPoint * $0.percentage }
        var points = products.map { $0 / 100 }
        let leftover = totalPoint - points.reduce(0, +)
        let priority = products.indices.sorted { lhs, rhs in
            let lhsRemainder = products[lhs] % 100
            let rhsRemainder = products[rhs] % 100
            return lhsRemainder == rhsRemainder ? lhs < rhs : lhsRemainder > rhsRemainder
        }
        for index in priority.prefix(leftover) {
            points[index] += 1
        }
        return points
    }

    /// 確定できない理由。確定できるならnil
    var validationError: HouseworkExecutorAllocationError? {
        guard !entries.isEmpty else { return .noExecutor }
        guard totalPercentage == 100 else { return .percentageNotHundred(total: totalPercentage) }
        guard points.allSatisfy({ $0 >= 1 }) else { return .zeroPoint }
        return nil
    }

    /// 保存する担当者を作る
    /// - Throws: 確定できない配分のときは、その理由
    func makeExecutors() throws(HouseworkExecutorAllocationError) -> [HouseworkExecutor] {
        if let validationError {
            throw validationError
        }

        return zip(entries, points).map { entry, point in
            .init(userId: entry.userId, percentage: entry.percentage, point: point)
        }
    }

}

private extension HouseworkExecutorAllocation {

    /// 均等割り。割り切れない分は先頭から1%ずつ足す
    static func evenEntries(userIds: [String]) -> [Entry] {
        guard !userIds.isEmpty else { return [] }

        let base = 100 / userIds.count
        let remainder = 100 % userIds.count
        return userIds.enumerated().map { index, userId in
            .init(userId: userId, percentage: base + (index < remainder ? 1 : 0))
        }
    }

}
