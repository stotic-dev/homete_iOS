//
//  EncouragementCommentStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// ダッシュボードに出す、ねぎらいのコメントの状態
///
/// 節目（`EncouragementMilestone`）ごとに1回だけFoundation Modelsで生成し、端末に保存する。
/// 生成できないとき・生成結果がトーンのガイドラインに反するときは、固定文言を出す（ADR-0040）。
@MainActor
@Observable
public final class EncouragementCommentStore {

    // MARK: state

    /// 表示するコメント。生成を待っている間は`nil`
    public private(set) var comment: EncouragementComment?

    /// 進行中の生成。同じ節目の生成を二重に走らせないために持つ
    private var generation: Generation?
    /// `update`を呼ばれた回数。後から始まった更新の結果を、先に始まった生成の結果で上書きしないために使う
    private var updateCount = 0

    // MARK: Dependencies

    private let houseworkManager: HouseworkManager
    private let encouragementCommentClient: EncouragementCommentClient
    private let cacheClient: EncouragementCommentCacheClient

    // MARK: initialize

    public init(
        houseworkManager: HouseworkManager,
        encouragementCommentClient: EncouragementCommentClient,
        cacheClient: EncouragementCommentCacheClient
    ) {
        self.houseworkManager = houseworkManager
        self.encouragementCommentClient = encouragementCommentClient
        self.cacheClient = cacheClient
    }

    /// プレビュー用に、表示するコメントを決めて生成する
    public convenience init(comment: EncouragementComment?) {
        self.init(
            houseworkManager: .init(houseworkClient: .previewValue),
            encouragementCommentClient: .previewValue,
            cacheClient: .previewValue
        )
        self.comment = comment
    }

    // MARK: public method

    /// 最新の家事の実施状況で、表示するコメントを決め直す
    ///
    /// 家事やメンバーが変わるたびに呼ばれる想定。節目が変わらなければ保存済みのコメントを出すだけで、生成はしない。
    /// 家事の初回取得とメンバーの読み込みが終わるまでは何もしない。そろう前に判定すると、実績がある日でも
    /// 一瞬「実績なし」のコメントを出したり、メンバー別の貢献度が欠けたまま生成して保存したりしてしまうため。
    /// - Parameters:
    ///   - ownUserId: 見ている本人。ログイン情報から渡す
    ///   - todayTotalCount: 今日の家事の件数。テンプレートの未登録分を含めて数えたもの
    public func update(
        ownUserId: String,
        members: CohabitantMemberList,
        todayTotalCount: Int,
        now: Date,
        calendar: Calendar
    ) async {
        guard await houseworkManager.fetchedRange != nil,
              members.value.contains(where: { $0.id == ownUserId }) else { return }

        updateCount += 1
        let updateId = updateCount
        let context = await EncouragementContext.make(
            allItems: houseworkManager.allItems,
            members: members,
            ownUserId: ownUserId,
            todayTotalCount: todayTotalCount,
            now: now,
            calendar: calendar
        )
        let key = EncouragementGenerationKey(
            userId: ownUserId,
            day: calendar.startOfDay(for: now),
            milestone: EncouragementMilestone(context: context)
        )

        guard key.milestone != .noActivity else {
            let neutral = EncouragementFixedComment.make(milestone: .noActivity, now: now, calendar: calendar)
            apply(neutral, updateId: updateId)
            return
        }
        if let cached = await cachedComment(for: key) {
            apply(cached, updateId: updateId)
            return
        }

        let task = generationTask(for: key, context: context, now: now, calendar: calendar)
        if updateId == updateCount {
            comment = nil
        }
        await apply(task.value, updateId: updateId)
    }

}

// MARK: private

private extension EncouragementCommentStore {

    /// 進行中の生成と、その単位
    struct Generation {

        let key: EncouragementGenerationKey
        let task: Task<EncouragementComment, Never>

    }

    /// 後から始まった更新がなければ、表示するコメントを差し替える
    func apply(_ comment: EncouragementComment, updateId: Int) {
        guard updateId == updateCount else { return }

        self.comment = comment
    }

    /// 保存済みのコメントのうち、今の節目で出してよいものを返す
    ///
    /// 全て完了した後に家事が追加されて未完了に戻っても、その日のうちは全部完了のコメントを出し続ける。
    func cachedComment(for key: EncouragementGenerationKey) async -> EncouragementComment? {
        guard let cache = await cacheClient.load(),
              cache.userId == key.userId,
              cache.day == key.day,
              cache.milestone == key.milestone || cache.milestone == .allCompleted else { return nil }

        return cache.comment
    }

    /// 同じ節目の生成が進んでいればそれを返し、なければ新しく始める
    ///
    /// 生成はViewのタスクから切り離して走らせる。家事の更新でViewのタスクがキャンセルされても、
    /// 生成と保存は最後まで行い、同じ節目でもう一度生成し直さないようにする。
    func generationTask(
        for key: EncouragementGenerationKey,
        context: EncouragementContext,
        now: Date,
        calendar: Calendar
    ) -> Task<EncouragementComment, Never> {
        if let generation, generation.key == key {
            return generation.task
        }

        let task = Task {
            let comment = await makeComment(context: context, milestone: key.milestone, now: now, calendar: calendar)
            await cacheClient.save(.init(userId: key.userId, day: key.day, milestone: key.milestone, comment: comment))
            return comment
        }
        generation = .init(key: key, task: task)
        return task
    }

    /// Foundation Modelsで生成し、使えない・トーンに反するときは固定文言にする
    ///
    /// 固定文言にした場合も保存し、同じ節目で何度も生成を試みない。
    func makeComment(
        context: EncouragementContext,
        milestone: EncouragementMilestone,
        now: Date,
        calendar: Calendar
    ) async -> EncouragementComment {
        do {
            let text = try await encouragementCommentClient.generate(context)
            if let validated = EncouragementToneValidator.validated(text) {
                return .init(text: validated, kind: .selfPraise, source: .generated)
            }
            print("encouragement comment was rejected by tone validator: \(text)")
        } catch {
            print("failed to generate encouragement comment: \(error)")
        }
        return EncouragementFixedComment.make(milestone: milestone, now: now, calendar: calendar)
    }

}

/// 生成の単位。同じユーザー・同じ日・同じ節目の生成は1回だけにする
private struct EncouragementGenerationKey: Equatable {

    let userId: String
    let day: Date
    let milestone: EncouragementMilestone

}
