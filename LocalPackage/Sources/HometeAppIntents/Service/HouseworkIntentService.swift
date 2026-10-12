//
//  HouseworkIntentService.swift
//  LocalPackage
//

import ContributionFeature
import Foundation
import HometeDomain
import HouseworkFeature

/// App Intentで、家事を探して完了にする・ありがとうを伝える・今月のがんばりを集計する
///
/// 実行するたびにサーバーから家事を取り直し、画面と同じ判定（`TodayHouseworkSummary`・`ThanksPromptSummary`）で対象を決める。
/// App Intentsの型に依存させず、ユニットテストできるようにする。
struct HouseworkIntentService {

    let sessionUseCase: AppIntentSessionUseCase
    let commandUseCase: HouseworkCommandUseCase
    let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase
    let calendar: Calendar

    /// 今日の未完了の家事の名前（同じ名前は1つにまとめ、ダッシュボードの未完了の家事と同じ順に並べる）
    func incompleteTitles(now: Date) async throws -> [String] {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: false)
        let summary = try await todaySummary(session: session, now: now)
        var titles: [String] = []
        for item in summary.incompleteItems where !titles.contains(item.title) {
            titles.append(item.title)
        }
        return titles
    }

    /// 今日の家事のうち、名前が一致する未完了の家事を完了にする
    ///
    /// 頑張り度を選ぶ画面を通らないため、自分だけを担当者にして「ふつう」で記録する（一括完了と同じ）。
    /// 同じ名前の未完了の家事が複数あるときは、ダッシュボードの未完了の家事と同じ並びの先頭を完了にする。
    func completeHousework(title: String, now: Date) async throws -> CompleteHouseworkOutcome {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        let summary = try await todaySummary(session: session, now: now)
        guard let target = summary.incompleteItems.first(where: { $0.title == title }) else {
            let isCompleted = summary.allItems.contains { $0.title == title && $0.state == .completed }
            return isCompleted ? .alreadyCompleted : .notFound
        }

        let point = target.originalItem.point
        try await commandUseCase.complete(
            current: target.originalItem,
            now: now,
            reporter: session.account,
            executors: [.solo(userId: session.account.id, point: point)],
            effort: .normal,
            executorNames: [session.account.userName],
            comment: "",
            cohabitantId: session.cohabitantId,
            isRegistered: target.isRegistered,
            step: .appIntent,
            delivery: .awaiting
        )
        // アプリを開いていないと家事の購読でふりかえり通知を予約できないため、ここで予約する
        await dailyCompletionReminderUseCase.syncToday(hasCompletedHousework: true, now: now, calendar: calendar)
        return .completed(point: point)
    }

    /// ありがとうを伝えられる家事（今日と昨日に同居人が終えた家事のうち、まだ自分が送っていないもの）
    func thanksCandidates(now: Date) async throws -> [ThanksCandidate] {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: false)
        return try await thanksContext(session: session, now: now).candidates
    }

    /// ありがとうを伝える
    /// - Parameter comment: 添えるコメント。空なら添えず、通知も送らない（ハートのタップと同じ）
    func sendThanks(houseworkId: String, comment: String?, now: Date) async throws -> SendThanksOutcome {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        let context = try await thanksContext(session: session, now: now)
        // 送った後や、未完了に戻された家事は候補から外れる。コメントの編集にもしない
        guard let candidate = context.candidates.first(where: { $0.id == houseworkId }),
              let target = context.items.item(candidate.item) else {
            return .notFound
        }

        let trimmedComment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isRecorded = try await commandUseCase.sendThanks(
            current: target,
            sender: session.account,
            comment: trimmedComment?.isEmpty == false ? trimmedComment : nil,
            now: now,
            cohabitantId: session.cohabitantId,
            step: .appIntent,
            delivery: .awaiting
        )
        return isRecorded ? .sent(houseworkTitle: candidate.title) : .notFound
    }

    /// 今月のメンバーごとのがんばり
    func monthlySummary(now: Date) async throws -> ContributionMonthlySummary {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: false)
        let today = calendar.startOfDay(for: now)
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? today
        let elapsedDays = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0
        let days = (0 ... elapsedDays).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfMonth) }
        async let stored = sessionUseCase.fetchHousework(session: session, days: days, calendar: calendar)
        async let members = sessionUseCase.fetchMembers(session: session)
        return try await .make(
            items: stored.value.flatMap(\.items),
            members: members,
            month: now,
            myUserId: session.account.id,
            calendar: calendar
        )
    }

}

/// アプリを開かずに家事を完了にした結果
enum CompleteHouseworkOutcome: Equatable {

    /// 完了にした
    case completed(point: Int)
    /// 今日の家事に、その名前の家事が無い
    case notFound
    /// その名前の家事は、今日はもう終わっている
    case alreadyCompleted

}

/// アプリを開かずにありがとうを伝えた結果
enum SendThanksOutcome: Equatable {

    /// ありがとうを記録した
    case sent(houseworkTitle: String)
    /// ありがとうを伝えられる家事ではなかった（送信済み・未完了に戻された・見つからない）
    case notFound
    /// 家事を指定せずに実行したが、ありがとうを伝えられる家事が1件も無かった
    case noCandidate

}

/// ありがとうを伝えられる家事
struct ThanksCandidate: Equatable {

    let item: HouseworkItem
    /// 家事を担当した、自分以外のメンバーの名前（メンバー一覧の順）
    let executorNames: [String]

    var id: String {
        item.id
    }

    var title: String {
        item.title
    }

}

private extension HouseworkIntentService {

    func todaySummary(session: AppIntentSession, now: Date) async throws -> TodayHouseworkSummary {
        let today = calendar.startOfDay(for: now)
        async let stored = sessionUseCase.fetchHousework(session: session, days: [today], calendar: calendar)
        async let templateContext = sessionUseCase.fetchTemplateContext(session: session)
        return try await .make(
            storedAllItems: stored,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            now: now,
            calendar: calendar,
            storagePolicy: HouseworkStoragePolicy(isPremium: session.account.isPremium)
        )
    }

    func thanksContext(
        session: AppIntentSession,
        now: Date
    ) async throws -> (items: StoredAllHouseworkList, candidates: [ThanksCandidate]) {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        async let stored = sessionUseCase.fetchHousework(session: session, days: [yesterday, today], calendar: calendar)
        async let members = sessionUseCase.fetchMembers(session: session)
        let (items, memberList) = try await (stored, members)

        let ownUserId = session.account.id
        let summary = ThanksPromptSummary.make(
            storedAllItems: items,
            members: memberList,
            ownUserId: ownUserId,
            now: now,
            calendar: calendar
        )
        let candidates = summary.thankableItems
            .filter { $0.sentThanks(ownUserId: ownUserId) == nil }
            .map { item in
                ThanksCandidate(
                    item: item.originalItem,
                    executorNames: item.executors
                        .map(\.userId)
                        .filter { $0 != ownUserId }
                        .compactMap { memberList.userName($0) }
                )
            }
        return (items, candidates)
    }

}
