//
//  EncouragementCommentStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct EncouragementCommentStoreTest {

    private let calendar = Calendar.japanese
    private let now = Date.previewDate(year: 2026, month: 10, day: 6, hour: 20)
    private let today = Date.previewDate(year: 2026, month: 10, day: 6)
    private let members = CohabitantMemberList(value: [.init(id: "own", userName: "たろう")], ownId: "own")

    @Test("自分の今日の実績がなければ、生成せずに中立の固定文言を出す")
    func update_noActivity_showsNeutralFixedComment() async {
        // Arrange
        let store = makeStore(
            allItems: [],
            generate: { _ in
                Issue.record("生成してはいけない")
                return ""
            }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        let expected = EncouragementComment(
            text: "今日も一日おつかれさまです。気が向いたときに、家事リストをのぞいてみてください",
            kind: .neutral,
            source: .fixed
        )
        #expect(store.comment == expected)
    }

    @Test("今日の実績があり保存済みのコメントがなければ、生成したコメントを出して保存する")
    func update_inProgressWithoutCache_showsGeneratedCommentAndSaves() async {
        // Arrange
        let saved = TestLockedArray<EncouragementCommentCache>()
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in "「洗濯、おつかれさまです」" },
            save: { await saved.append($0) }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        let expectedComment = EncouragementComment(text: "洗濯、おつかれさまです", kind: .selfPraise, source: .generated)
        #expect(store.comment == expectedComment)
        let expectedCaches = [
            EncouragementCommentCache(userId: "own", day: today, milestone: .inProgress, comment: expectedComment),
        ]
        #expect(await saved.values == expectedCaches)
    }

    @Test(
        "同じ日・同じ節目、または全部完了のコメントが保存済みなら、生成せずにそれを出す",
        arguments: [EncouragementMilestone.inProgress, .allCompleted]
    )
    func update_cachedComment_showsCachedComment(cachedMilestone: EncouragementMilestone) async {
        // Arrange
        let cachedComment = EncouragementComment(text: "保存したコメント", kind: .selfPraise, source: .generated)
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in
                Issue.record("生成してはいけない")
                return ""
            },
            load: { .init(userId: "own", day: today, milestone: cachedMilestone, comment: cachedComment) }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        #expect(store.comment == cachedComment)
    }

    @Test(
        "保存済みのコメントが別の日・別のユーザー・前の節目のものなら、生成し直す",
        arguments: [
            (
                userId: "own",
                day: Date.previewDate(year: 2026, month: 10, day: 5),
                milestone: EncouragementMilestone.inProgress
            ),
            (userId: "other", day: .previewDate(year: 2026, month: 10, day: 6), milestone: .inProgress),
            (userId: "own", day: .previewDate(year: 2026, month: 10, day: 6), milestone: .inProgress),
        ]
    )
    func update_staleCache_generatesComment(userId: String, day: Date, milestone: EncouragementMilestone) async {
        // Arrange
        let cachedComment = EncouragementComment(text: "保存したコメント", kind: .selfPraise, source: .generated)
        // 今日の家事が全て完了しているので、節目は全部完了
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in "今日もおつかれさまでした" },
            load: { .init(userId: userId, day: day, milestone: milestone, comment: cachedComment) }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 1, now: now, calendar: calendar)

        // Assert
        let expected = EncouragementComment(text: "今日もおつかれさまでした", kind: .selfPraise, source: .generated)
        #expect(store.comment == expected)
    }

    @Test("生成に失敗したら、ねぎらいの固定文言を出して保存する")
    func update_generateFailed_showsFixedCommentAndSaves() async {
        // Arrange
        let saved = TestLockedArray<EncouragementCommentCache>()
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in throw EncouragementCommentError.unavailable },
            save: { await saved.append($0) }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        let expectedComment = EncouragementComment(
            text: "毎日の積み重ねが、心地よい暮らしにつながっています。今日もおつかれさまです",
            kind: .selfPraise,
            source: .fixed
        )
        #expect(store.comment == expectedComment)
        let expectedCaches = [
            EncouragementCommentCache(userId: "own", day: today, milestone: .inProgress, comment: expectedComment),
        ]
        #expect(await saved.values == expectedCaches)
    }

    @Test("生成したコメントが禁止表現を含むなら、ねぎらいの固定文言を出す")
    func update_generatedForbiddenText_showsFixedComment() async {
        // Arrange
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in "もっと家事をしましょう" }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        let expected = EncouragementComment(
            text: "毎日の積み重ねが、心地よい暮らしにつながっています。今日もおつかれさまです",
            kind: .selfPraise,
            source: .fixed
        )
        #expect(store.comment == expected)
    }

    @Test("家事の初回取得が終わるまでは、コメントを決めずに枠だけの表示のままにする")
    func update_beforeFetched_keepsPlaceholder() async {
        // Arrange
        let store = makeStore(
            allItems: [],
            isFetched: false,
            generate: { _ in
                Issue.record("生成してはいけない")
                return ""
            }
        )

        // Act
        await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)

        // Assert
        #expect(store.comment == nil)
    }

    @Test("メンバーの読み込みが終わるまでは、コメントを決めずに枠だけの表示のままにする")
    func update_beforeMembersLoaded_keepsPlaceholder() async {
        // Arrange
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in
                Issue.record("生成してはいけない")
                return ""
            }
        )

        // Act
        await store.update(
            ownUserId: "own",
            members: .init(value: [], ownId: "own"),
            todayTotalCount: 2,
            now: now,
            calendar: calendar
        )

        // Assert
        #expect(store.comment == nil)
    }

    @Test("同じ節目の更新が重なっても、生成は1回だけ行う")
    func update_concurrentUpdates_generatesOnce() async {
        // Arrange
        let gate = TestGate()
        let counter = TestCounter()
        let store = makeStore(
            allItems: [ownCompletedItem()],
            generate: { _ in
                await counter.increment()
                await gate.wait()
                return "洗濯、おつかれさまです"
            }
        )
        let firstUpdate = Task {
            await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)
        }
        await gate.waitUntilArrived()

        // Act
        let secondUpdate = Task {
            await store.update(ownUserId: "own", members: members, todayTotalCount: 2, now: now, calendar: calendar)
        }
        gate.open()
        await firstUpdate.value
        await secondUpdate.value

        // Assert
        #expect(await counter.value == 1)
    }

}

private extension EncouragementCommentStoreTest {

    func makeStore(
        allItems: [HouseworkItem],
        isFetched: Bool = true,
        generate: @escaping @Sendable (EncouragementContext) async throws -> String,
        // デフォルト引数にasyncクロージャを書くと、Xcode 26でビルドしたテストの並列実行で落ちるため`nil`にする
        load: (@Sendable () async -> EncouragementCommentCache?)? = nil,
        save: (@Sendable (EncouragementCommentCache) async -> Void)? = nil
    ) -> EncouragementCommentStore {
        .init(
            houseworkManager: .init(
                houseworkClient: .previewValue,
                allItems: allItems,
                fetchedRange: isFetched ? .distantPast ... now : nil
            ),
            encouragementCommentClient: .init(generate: generate),
            cacheClient: .init(load: load, save: save)
        )
    }

    /// 今日自分が終えた家事
    func ownCompletedItem() -> HouseworkItem {
        .makeForTest(id: 1, indexedDate: today, title: "洗濯", state: .completed, executorId: "own")
    }

}
