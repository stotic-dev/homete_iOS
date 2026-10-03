//
//  HouseworkExecutorAllocation.swift
//  LocalPackage
//

/// 家事の担当者の選択と、ポイントの配分
///
/// 家事を完了にするときと、完了済みの家事に手伝った人を足すとき（`forAddingExecutors`）の両方で使う。
/// 担当者の並び順は`memberIds`（`CohabitantMemberList.value`の順。自分が先頭）に合わせる。
/// 均等割りの端数と、ポイントへの換算で小数部分が同じだったときの優先順は、どちらもこの順で決める。
/// 例外は`forAddingExecutors`で作った直後で、保存済みの配分を再現するため保存時の並び順を引き継ぐ。
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
    /// 家事のポイント（頑張り度で上乗せする前）。選べる人数の上限はこのポイントで決める
    public let basePoint: Int
    /// 選択を外せない担当者のユーザーID
    ///
    /// 完了済みの家事に手伝った人を足すときの、もともとの担当者が入る。完了にするときは空。
    public let lockedIds: [String]
    /// 頑張り度
    public private(set) var effort: HouseworkEffort
    /// 選んだ担当者と割合（メンバー一覧の並び順。`forAddingExecutors`の初期値だけ保存時の並び順）
    public private(set) var entries: [Entry]

    /// - Parameters:
    ///   - selectedIds: 最初に選んでおく担当者。選べる人数の上限を超えた分は先頭から切り詰める
    ///   - lockedIds: 選択を外せない担当者
    public init(
        memberIds: [String],
        selectedIds: [String],
        basePoint: Int,
        effort: HouseworkEffort = .normal,
        lockedIds: [String] = []
    ) {
        self.memberIds = memberIds
        self.basePoint = basePoint
        self.lockedIds = lockedIds
        self.effort = effort
        let orderedIds = memberIds
            .filter { selectedIds.contains($0) }
            .prefix(Self.maxExecutorCount(basePoint: basePoint))
        entries = Self.evenEntries(userIds: Array(orderedIds))
    }

    /// 完了済みの家事に手伝った人を足すときの配分を作る
    ///
    /// 家事の合計ポイントは変えずに配り直すため、配分の対象は上乗せ後のポイント（`HouseworkItem.earnedPoint`）。
    /// 頑張り度はこの操作では変えないので、上乗せしない「ふつう」を指定して`totalPoint`を`earnedPoint`と
    /// 一致させる。保存された`effort`から計算し直さないのは、上乗せ後の配分と対応しない場合があるため（ADR-0024）。
    ///
    /// もともとの担当者は外せないようにし、割合と並び順も保存済みのまま引き継ぐ。開いて保存しただけで
    /// 配分が変わらないようにするためで、人を足したときは`toggle(_:)`が全員を均等割りにし直す。
    /// メンバー一覧に居ない担当者（アカウントを削除した同居人）は引き継げないため、`entries`には入らない。
    /// この場合は割合の合計が100%にならず保存できず、`canAddExecutor`も`false`になる。
    /// - Parameter executors: もともとの担当者。`percentage`と並び順をそのまま初期値に使う
    public static func forAddingExecutors(
        memberIds: [String],
        executors: [HouseworkExecutor],
        earnedPoint: Int
    ) -> Self {
        let executorIds = executors.map(\.userId)
        var allocation = Self(
            memberIds: memberIds,
            selectedIds: executorIds,
            basePoint: earnedPoint,
            effort: .normal,
            lockedIds: executorIds
        )
        // 保存済みの割合だけでなく、保存済みの並び順も引き継ぐ。ポイントへの換算は端数の行き先が
        // 並び順で決まるため、メンバー一覧の並び順（自分が先頭）に並べ替えると、同じ家事でも
        // 見ている人によって1ptの行き先が入れ替わってしまう
        allocation.entries = executors
            .filter { memberIds.contains($0.userId) }
            .map { .init(userId: $0.userId, percentage: $0.percentage) }
        return allocation
    }

    /// 担当者に配分するポイント（頑張り度で上乗せした後）
    public var totalPoint: Int {
        effort.boostedPoint(basePoint)
    }

}

// MARK: - 担当者の選択

public extension HouseworkExecutorAllocation {

    /// 選べる人数の上限
    ///
    /// 0ptの担当者を許さないため、家事のポイントより多い人数は選べない。
    /// 上乗せ後のポイントは上乗せ前以上なので、上乗せ前のポイントで上限を決めておけば、
    /// 頑張り度を切り替えても選んだ担当者が上限を超えない。
    static func maxExecutorCount(basePoint: Int) -> Int {
        max(basePoint, 1)
    }

    /// この配分で選べる人数の上限
    ///
    /// 上限の基準になるポイントが完了時（上乗せ前）と手伝った人の追加時（上乗せ後）で違うため、
    /// 呼び出し側が基準を意識しなくて済むようにここから引く。
    var maxExecutorCount: Int {
        Self.maxExecutorCount(basePoint: basePoint)
    }

    func isSelected(_ userId: String) -> Bool {
        entries.contains { $0.userId == userId }
    }

    /// 選択を切り替えられるかどうか
    ///
    /// 選択済みの担当者はいつでも外せる。未選択のメンバーは、人数の上限に達していなければ選べる。
    /// `lockedIds`の担当者はどちらもできない。
    func canToggle(_ userId: String) -> Bool {
        guard !lockedIds.contains(userId) else { return false }

        return isSelected(userId) || entries.count < maxExecutorCount
    }

    /// 担当者をまだ足せるかどうか
    ///
    /// 人数の上限に達していて選べない場合と、同居人が自分だけで足せる相手がいない場合を区別しない。
    /// どちらも「これ以上足せない」ことに変わりはなく、呼び出し側は導線を出すかどうかだけを決める。
    ///
    /// メンバー一覧に居ない担当者（アカウントを削除した同居人）がいる家事も足せないものとして扱う。
    /// 足すと均等割りをやり直す際に、その人の配分が黙って残りのメンバーへ移ってしまうため。
    var canAddExecutor: Bool {
        guard lockedIds.allSatisfy({ memberIds.contains($0) }) else { return false }

        return entries.count < maxExecutorCount && memberIds.contains { !isSelected($0) }
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

// MARK: - 頑張り度

public extension HouseworkExecutorAllocation {

    /// 頑張り度を変える
    ///
    /// 選んだ担当者と割合はそのままにして、配分するポイントだけを変える。
    mutating func updateEffort(_ effort: HouseworkEffort) {
        self.effort = effort
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
