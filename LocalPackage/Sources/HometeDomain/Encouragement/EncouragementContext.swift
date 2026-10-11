//
//  EncouragementContext.swift
//  LocalPackage
//

import Foundation

/// ねぎらいのコメントを生成するときに渡す、家事の実施状況
///
/// 自分の実績に加えて、今日の家事の進み具合と今月のメンバー別の貢献度を持ち、全体を見たコメントにする。
/// 「まだ終わっていない」ことを指摘する材料を与えないよう、未完了の家事のタイトルや件数は持たない。
public struct EncouragementContext: Equatable, Sendable {

    /// 自分の実績
    public let own: OwnActivity
    /// 今日の家事の進み具合（世帯全体）
    public let today: TodayProgress
    /// 今月のメンバー別の貢献度（自分が先頭）
    public let monthlyMembers: [MonthlyMemberContribution]

    public init(own: OwnActivity, today: TodayProgress, monthlyMembers: [MonthlyMemberContribution]) {
        self.own = own
        self.today = today
        self.monthlyMembers = monthlyMembers
    }

}

public extension EncouragementContext {

    /// 自分の実績
    struct OwnActivity: Equatable, Sendable {

        /// 今日自分が完了した家事のタイトル（完了した順に最大`titleLimit`件）
        public let todayCompletedTitles: [String]
        /// 今日自分が完了した件数
        public let todayCompletedCount: Int
        /// 今日「がんばった」「超頑張った」で完了した件数
        public let todayEffortfulCount: Int
        /// 今日を含む直近7日に自分が完了した件数
        public let weeklyCompletedCount: Int
        /// 今日まで連続で1件以上完了した日数。今日が0件なら0
        public let streakDays: Int

        public init(
            todayCompletedTitles: [String],
            todayCompletedCount: Int,
            todayEffortfulCount: Int,
            weeklyCompletedCount: Int,
            streakDays: Int
        ) {
            self.todayCompletedTitles = todayCompletedTitles
            self.todayCompletedCount = todayCompletedCount
            self.todayEffortfulCount = todayEffortfulCount
            self.weeklyCompletedCount = weeklyCompletedCount
            self.streakDays = streakDays
        }

    }

    /// 今日の家事の進み具合（世帯全体）
    struct TodayProgress: Equatable, Sendable {

        /// 今日の家事の件数（テンプレートの未登録分を含む）
        public let totalCount: Int
        /// 今日完了した件数
        public let completedCount: Int

        public init(totalCount: Int, completedCount: Int) {
            self.totalCount = totalCount
            self.completedCount = completedCount
        }

        /// 今日の家事が全て完了したか。家事が0件の日は完了とみなさない
        public var isAllCompleted: Bool {
            totalCount > 0 && completedCount >= totalCount
        }

    }

    /// 今月のメンバーごとの貢献度
    struct MonthlyMemberContribution: Equatable, Sendable {

        public let userName: String
        /// 自分かどうか
        public let isOwn: Bool
        /// 今月完了した件数
        public let completedCount: Int
        /// 今月のポイント（担当者ごとに配分されたポイントの合計）
        public let point: Int
        /// 今月よく完了した家事のタイトル（回数の多い順に最大`frequentTitleLimit`件）
        public let frequentTitles: [String]

        public init(userName: String, isOwn: Bool, completedCount: Int, point: Int, frequentTitles: [String]) {
            self.userName = userName
            self.isOwn = isOwn
            self.completedCount = completedCount
            self.point = point
            self.frequentTitles = frequentTitles
        }

    }

}

// MARK: 集計

public extension EncouragementContext {

    /// 今日自分が完了した家事のタイトルを渡す上限
    static let titleLimit = 5
    /// 今月よく完了した家事のタイトルを渡す上限
    static let frequentTitleLimit = 3

    /// 家事の記録から、コメントの生成に渡す実施状況を集計する
    ///
    /// 複数人で担当した家事は、担当者それぞれに1件と数える（貢献度の集計と同じ考え方）。
    /// - Parameters:
    ///   - allItems: 取得済みの家事（直近7日・今月の集計に使うため、リスナーの±N日より広い範囲を渡す）
    ///   - ownUserId: 見ている本人。メンバー一覧の`ownId`ではなく、ログイン情報から渡す
    ///   - todayTotalCount: 今日の家事の件数。テンプレートの未登録分を含めるため、呼び出し側で数えて渡す
    static func make( // swiftlint:disable:this function_parameter_count
        allItems: [HouseworkItem],
        members: CohabitantMemberList,
        ownUserId: String,
        todayTotalCount: Int,
        now: Date,
        calendar: Calendar
    ) -> Self {
        let today = calendar.startOfDay(for: now)
        let completedItems = allItems.filter { $0.state == .completed }
        return .init(
            own: makeOwnActivity(
                completedItems: completedItems,
                ownId: ownUserId,
                today: today,
                calendar: calendar
            ),
            today: .init(
                totalCount: todayTotalCount,
                completedCount: completedItems.count { calendar.isDate($0.indexedDate.value, inSameDayAs: today) }
            ),
            monthlyMembers: makeMonthlyMembers(
                completedItems: completedItems,
                members: members,
                ownUserId: ownUserId,
                today: today,
                calendar: calendar
            )
        )
    }

}

private extension EncouragementContext {

    static func makeOwnActivity(
        completedItems: [HouseworkItem],
        ownId: String,
        today: Date,
        calendar: Calendar
    ) -> OwnActivity {
        let ownItems = completedItems.filter { item in
            item.executors.contains { $0.userId == ownId }
        }
        let ownCountByDay = Dictionary(grouping: ownItems) {
            calendar.startOfDay(for: $0.indexedDate.value)
        }
        .mapValues(\.count)

        let todayItems = ownItems
            .filter { calendar.isDate($0.indexedDate.value, inSameDayAs: today) }
            .sorted { ($0.executedAt ?? .distantFuture) < ($1.executedAt ?? .distantFuture) }
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        return .init(
            todayCompletedTitles: Array(todayItems.map(\.title).prefix(titleLimit)),
            todayCompletedCount: todayItems.count,
            todayEffortfulCount: todayItems.count { $0.effort != .normal },
            weeklyCompletedCount: ownCountByDay
                .filter { weekStart ... today ~= $0.key }
                .values
                .reduce(0, +),
            streakDays: streakDays(ownCountByDay: ownCountByDay, today: today, calendar: calendar)
        )
    }

    /// 今日から1日ずつ遡り、1件以上完了した日が続いた日数を数える
    static func streakDays(ownCountByDay: [Date: Int], today: Date, calendar: Calendar) -> Int {
        var streak = 0
        var day = today
        while (ownCountByDay[day] ?? 0) > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    static func makeMonthlyMembers(
        completedItems: [HouseworkItem],
        members: CohabitantMemberList,
        ownUserId: String,
        today: Date,
        calendar: Calendar
    ) -> [MonthlyMemberContribution] {
        let monthItems = completedItems.filter {
            calendar.isDate($0.indexedDate.value, equalTo: today, toGranularity: .month)
        }
        return members.value.map { member in
            let records = monthItems.compactMap { item -> (title: String, point: Int)? in
                guard let executor = item.executors.first(where: { $0.userId == member.id }) else { return nil }
                return (item.title, executor.point)
            }
            return .init(
                userName: member.userName,
                isOwn: member.id == ownUserId,
                completedCount: records.count,
                point: records.reduce(0) { $0 + $1.point },
                frequentTitles: frequentTitles(records.map(\.title))
            )
        }
    }

    /// 回数の多い順（同数ならタイトル順）に、上位のタイトルを返す
    static func frequentTitles(_ titles: [String]) -> [String] {
        Dictionary(grouping: titles) { $0 }
            .mapValues(\.count)
            .sorted { ($1.value, $0.key) < ($0.value, $1.key) }
            .prefix(frequentTitleLimit)
            .map(\.key)
    }

}
