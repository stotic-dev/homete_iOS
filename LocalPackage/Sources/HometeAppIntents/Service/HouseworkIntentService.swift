//
//  HouseworkIntentService.swift
//  LocalPackage
//

import ContributionFeature
import Foundation
import HometeDomain
import HouseworkFeature
import os

/// App Intentで、家事を探して完了にする・ありがとうを伝える・今月のがんばりを集計する
///
/// 実行するたびにサーバーから家事を取り直し、画面と同じ判定（`TodayHouseworkSummary`・`ThanksPromptSummary`）で対象を決める。
/// App Intentsの型に依存させず、ユニットテストできるようにする。
struct HouseworkIntentService {

    let sessionUseCase: AppIntentSessionUseCase
    let commandUseCase: HouseworkCommandUseCase
    let dailyCompletionReminderUseCase: DailyCompletionReminderUseCase
    let calendar: Calendar
    /// 書き込みがサーバーに届くのを待つ時間。過ぎたら、オンラインになったら反映されることを伝えて返す
    var writeTimeout: Duration = .seconds(10)
    /// 新しく作る家事のID
    var idGenerator: @Sendable () -> String = { UUID().uuidString }

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

        let isDelivered = try await complete(
            target.originalItem,
            isRegistered: target.isRegistered,
            session: session,
            now: now
        )
        return isDelivered ? .completed(point: target.originalItem.point) : .pendingSync
    }

    /// ありがとうを伝えられる家事（今日に同居人が終えた家事のうち、まだ自分が送っていないもの）
    ///
    /// アプリのありがとうを伝えられる家事の一覧と同じく、今日の家事だけを対象にする
    func thanksCandidates(now: Date) async throws -> [ThanksCandidate] {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: false)
        return try await thanksCandidates(session: session, now: now)
    }

    /// ありがとうを伝える
    /// - Parameter comment: 添えるコメント。空なら添えず、通知も送らない（ハートのタップと同じ）
    func sendThanks(houseworkId: String, comment: String?, now: Date) async throws -> SendThanksOutcome {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        // 送った後や、未完了に戻された家事は候補から外れる。コメントの編集にもしない
        guard let candidate = try await thanksCandidates(session: session, now: now)
            .first(where: { $0.id == houseworkId }) else {
            return .notFound
        }
        let target = candidate.item

        let trimmedComment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        let thanksComment = trimmedComment?.isEmpty == false ? trimmedComment : nil
        let recordedResult = OSAllocatedUnfairLock(initialState: false)
        let isDelivered = try await awaitWrite { onWritten in
            let isRecorded = try await commandUseCase.sendThanks(
                current: target,
                sender: session.account,
                comment: thanksComment,
                now: now,
                cohabitantId: session.cohabitantId,
                step: .appIntent,
                delivery: .awaiting,
                onWritten: onWritten
            )
            recordedResult.withLock { $0 = isRecorded }
        }
        guard isDelivered else { return .pendingSync(houseworkTitle: candidate.title) }
        return recordedResult.withLock { $0 } ? .sent(houseworkTitle: candidate.title) : .notFound
    }

    /// グループのいつもの家事（カテゴリ内の並び順）
    func frequentItems() async throws -> [FrequentHouseworkItem] {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: false)
        return await sessionUseCase.fetchFrequentHousework(session: session).orderedItems
    }

    /// 声で伝えた家事の名前から、今日の家事と、似ているいつもの家事を探す
    ///
    /// 記録・登録のIntentは、この結果から確認や提案の聞き返しを決める。
    /// - Parameters:
    ///   - title: 話しかけた家事の名前（「洗濯干した」など）
    ///   - note: 登録で家事のメモに入れる補足。聞き返す前に、書ける文字数を超えていないかを確かめる
    func voicePlan(title: String, note: String?, now: Date) async throws -> VoiceHouseworkPlan {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        async let summary = todaySummary(session: session, now: now)
        async let frequentContext = sessionUseCase.fetchFrequentHousework(session: session)
        let normalizedTitle = FrequentHouseworkContext.normalize(title)
        let todaySummary = try await summary
        return await .init(
            title: normalizedTitle,
            todayMatch: .init(summary: todaySummary, title: normalizedTitle),
            todaySuggestions: similarIncompleteTitles(todaySummary, title: normalizedTitle),
            suggestions: frequentContext.similarItems(to: normalizedTitle),
            isNoteTooLong: !isWithinMemoLimit(note: trimmed(note), session: session)
        )
    }

    /// やった家事を記録する
    ///
    /// 今日の家事に同じ名前の未完了の家事があればそれを完了にし、無ければ新しく作って完了にする。
    /// 担当者は自分だけ、頑張り度は「ふつう」にする（`completeHousework`と同じ）。
    /// 新しく作る家事は、いつもの家事ならそのポイントとメモを、名前だけなら登録画面と同じ初期値のポイントを使う。
    func recordHousework(_ target: VoiceHouseworkTarget, now: Date) async throws -> RecordHouseworkOutcome {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        async let summary = todaySummary(session: session, now: now)
        async let resolved = resolve(target, session: session)
        let (todaySummary, resolvedTarget) = try await (summary, resolved)
        switch TodayHouseworkMatch(summary: todaySummary, title: resolvedTarget.title) {
        case let .incomplete(item):
            let isDelivered = try await complete(
                item.originalItem,
                isRegistered: item.isRegistered,
                session: session,
                now: now
            )
            return isDelivered
                ? .completed(title: item.title, point: item.originalItem.point)
                : .pendingSync(title: item.title)

        case let .completed(title):
            return .alreadyCompleted(title: title)

        case nil:
            let item = makeNewItem(resolvedTarget, session: session, now: now, note: "")
            let isDelivered = try await complete(item, isRegistered: false, session: session, now: now)
            return isDelivered ? .completed(title: item.title, point: item.point) : .pendingSync(title: item.title)
        }
    }

    /// これからやる家事を、今日の家事に登録する
    ///
    /// 今日の家事に同じ名前の未完了の家事があれば、重ねて登録しない。完了した家事なら、もう一度やるものとして登録する。
    /// 登録したことは同居人へ通知しない（家事の追加画面と同じ）。
    /// - Parameter note: 家事のメモに入れる、話しかけた内容の補足（「牛乳と卵」など）。いつもの家事のメモがあれば、その後ろに足す
    func registerHousework(
        _ target: VoiceHouseworkTarget,
        note: String?,
        now: Date
    ) async throws -> RegisterHouseworkOutcome {
        let session = try await sessionUseCase.resolve(requiresLatestVersion: true)
        async let summary = todaySummary(session: session, now: now)
        async let resolved = resolve(target, session: session)
        let (todaySummary, resolvedTarget) = try await (summary, resolved)
        if case let .incomplete(item) = TodayHouseworkMatch(summary: todaySummary, title: resolvedTarget.title) {
            return .alreadyRegistered(title: item.title)
        }

        let trimmedNote = trimmed(note)
        guard isWithinMemoLimit(note: trimmedNote, session: session) else {
            return .memoLimitExceeded
        }
        let item = makeNewItem(resolvedTarget, session: session, now: now, note: trimmedNote)
        let source: HouseworkRegisterSource = resolvedTarget.isFrequent ? .frequent : .manual
        let isDelivered = try await awaitWrite { onWritten in
            try await commandUseCase.register(
                newItems: [.init(item: item, source: source)],
                createdAt: now,
                cohabitantId: session.cohabitantId,
                step: .appIntent,
                memoLimitPolicy: HouseworkMemoLimitPolicy(isPremium: session.account.isPremium),
                onWritten: onWritten
            )
        }
        return isDelivered ? .registered(title: item.title) : .pendingSync(title: item.title)
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
    /// 通信できず、書き込みを端末に保存した。オンラインになったら反映される
    case pendingSync

}

/// アプリを開かずにありがとうを伝えた結果
enum SendThanksOutcome: Equatable {

    /// ありがとうを記録した
    case sent(houseworkTitle: String)
    /// ありがとうを伝えられる家事ではなかった（送信済み・未完了に戻された・見つからない）
    case notFound
    /// 家事を指定せずに実行したが、ありがとうを伝えられる家事が1件も無かった
    case noCandidate
    /// 通信できず、書き込みを端末に保存した。オンラインになったら反映される
    case pendingSync(houseworkTitle: String)

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

    /// 家事を自分だけを担当者にして「ふつう」で完了にし、ふりかえり通知の予約にも反映する
    /// - Returns: 書き込みがサーバーに届いたら`true`
    func complete(
        _ item: HouseworkItem,
        isRegistered: Bool,
        session: AppIntentSession,
        now: Date
    ) async throws -> Bool {
        let isDelivered = try await awaitWrite { onWritten in
            try await commandUseCase.complete(
                current: item,
                now: now,
                reporter: session.account,
                executors: [.solo(userId: session.account.id, point: item.point)],
                effort: .normal,
                executorNames: [session.account.userName],
                comment: "",
                cohabitantId: session.cohabitantId,
                isRegistered: isRegistered,
                step: .appIntent,
                delivery: .awaiting,
                onWritten: onWritten
            )
        }
        // アプリを開いていないと家事の購読でふりかえり通知を予約できないため、ここで予約する。
        // 書き込みが端末に保存されただけでも、完了にしたことに変わりはないので予約する
        await dailyCompletionReminderUseCase.syncToday(hasCompletedHousework: true, now: now, calendar: calendar)
        return isDelivered
    }

    /// 書き込みを待つ
    ///
    /// Firestoreはオフラインでも書き込みを端末に保存してオンラインになったら反映するが、書き込みはサーバーの応答まで返らない。
    /// 待ち続けるとSiriには失敗と出るのに後で記録されて食い違うため、`writeTimeout`を過ぎたら待つのをやめる。
    /// 書き込みは止めず、続き（Analytics・同居人への通知）はプロセスが動いている間に終われば行われる。
    /// 時間を測るのは書き込みが届くまでで、届いた後の同居人への通知は時間に関係なく送り終えるまで待つ。
    /// 通知が遅いだけで、記録できているのに「オンラインになったら反映」と伝えないようにするため。
    /// - Parameter operation: 書き込みが届いたら、受け取ったクロージャを呼ぶ
    /// - Returns: 書き込みがサーバーに届いたら`true`、`writeTimeout`を過ぎたら`false`
    func awaitWrite(
        _ operation: @escaping @Sendable (_ onWritten: @escaping @Sendable () -> Void) async throws -> Void
    ) async throws -> Bool {
        let pending = OSAllocatedUnfairLock<CheckedContinuation<Bool, any Error>?>(initialState: nil)
        let resume = { @Sendable (result: Result<Bool, any Error>) in
            let continuation = pending.withLock { continuation in
                defer { continuation = nil }
                return continuation
            }
            continuation?.resume(with: result)
        }
        let timeout = writeTimeout
        return try await withCheckedThrowingContinuation { continuation in
            pending.withLock { $0 = continuation }
            let timer = Task {
                try await Task.sleep(for: timeout)
                resume(.success(false))
            }
            Task {
                do {
                    try await operation { timer.cancel() }
                    resume(.success(true))
                } catch {
                    timer.cancel()
                    resume(.failure(error))
                }
            }
        }
    }

    func todaySummary(session: AppIntentSession, now: Date) async throws -> TodayHouseworkSummary {
        let today = calendar.startOfDay(for: now)
        async let stored = sessionUseCase.fetchHousework(session: session, days: [today], calendar: calendar)
        async let templateContext = sessionUseCase.fetchTemplateContext(session: session)
        return try await .make(
            storedAllItems: stored,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            now: now,
            calendar: calendar,
            // アプリはRevenueCatのエンタイトルメント（`SubscriptionStore`）で判定するが、IntentではRevenueCatを使わない。
            // 保持期限の判定用にアカウントへ保存している値を使う。購入・解約の直後で反映前なら、保持期限がずれうる
            storagePolicy: HouseworkStoragePolicy(isPremium: session.account.isPremium)
        )
    }

    func thanksCandidates(session: AppIntentSession, now: Date) async throws -> [ThanksCandidate] {
        let today = calendar.startOfDay(for: now)
        async let stored = sessionUseCase.fetchHousework(session: session, days: [today], calendar: calendar)
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
        return summary.thankableItems
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
    }

}
