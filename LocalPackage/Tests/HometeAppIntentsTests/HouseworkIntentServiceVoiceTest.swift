// swiftlint:disable file_length
//
//  HouseworkIntentServiceVoiceTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeAppIntents
import HometeDomain
import HouseworkFeature
import Testing

/// 声で伝えた家事の名前から、やった家事を記録する・これからやる家事を登録する
struct HouseworkIntentServiceVoiceTest {

    private let now = Date.previewDate(year: 2026, month: 10, day: 12, hour: 9)
    private let today = Date.previewDate(year: 2026, month: 10, day: 12)
    private let expiredAt = Date.previewDate(year: 2027, month: 10, day: 12)
    private let own = Account(id: "own", userName: "たろう", cohabitantId: "cohabitant")
    private let laundry = FrequentHouseworkItem(
        id: "frequent-laundry",
        title: "洗濯物干し",
        point: 30,
        categoryId: nil,
        sortOrder: 0,
        createdAt: .previewDate(year: 2026, month: 9, day: 1),
        updatedAt: .previewDate(year: 2026, month: 9, day: 1),
        memo: .init(text: "タオルは外", checklist: [])
    )

}

// MARK: - 探す

extension HouseworkIntentServiceVoiceTest {

    @Test("今日の家事に、言い方の揺れをそろえると同じ名前の未完了の家事があれば、その家事を返す")
    func voicePlanTodayIncomplete() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: "garbage",
            indexedDate: today,
            title: "ごみ出し",
            point: 10,
            expiredAt: expiredAt
        )
        let sut = makeSUT(items: [item])
        let expected = VoiceHouseworkPlan(
            title: "ゴミ出し",
            todayMatch: .incomplete(.init(originalItem: item, isRegistered: true)),
            todaySuggestions: [],
            suggestions: [],
            isNoteTooLong: false
        )

        // Act

        let actual = try await sut.voicePlan(title: " ゴミ出し ", note: nil, now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("今日の家事に無ければ、名前が似ているいつもの家事を返す")
    func voicePlanSuggestions() async throws {
        // Arrange

        let sut = makeSUT(items: [], frequentItems: [laundry])
        let expected = VoiceHouseworkPlan(
            title: "洗濯干した",
            todayMatch: nil,
            todaySuggestions: [],
            suggestions: [laundry],
            isNoteTooLong: false
        )

        // Act

        let actual = try await sut.voicePlan(title: "洗濯干した", note: nil, now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("今日の同じ名前の家事が終わっているだけなら、終わっていることを返す")
    func voicePlanTodayCompleted() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯物干し",
            state: .completed,
            executorId: "own",
            executedAt: now,
            expiredAt: expiredAt
        )
        let sut = makeSUT(items: [item], frequentItems: [laundry])
        let expected = VoiceHouseworkPlan(
            title: "洗濯物干し",
            todayMatch: .completed(title: "洗濯物干し"),
            todaySuggestions: [],
            suggestions: [laundry],
            isNoteTooLong: false
        )

        // Act

        let actual = try await sut.voicePlan(title: "洗濯物干し", note: nil, now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("名前が似ている今日の未完了の家事を、似ている順に返す（終わった家事は含めない）")
    func voicePlanTodaySuggestions() async throws {
        // Arrange

        let items: [HouseworkItem] = [
            .makeForTest(id: "fold", indexedDate: today, title: "洗濯物たたみ", point: 20, expiredAt: expiredAt),
            .makeForTest(id: "hang", indexedDate: today, title: "洗濯物干し", point: 10, expiredAt: expiredAt),
            .makeForTest(
                id: "done",
                indexedDate: today,
                title: "洗濯物干し（2回目）",
                state: .completed,
                executorId: "own",
                executedAt: now,
                expiredAt: expiredAt
            ),
            .makeForTest(id: "dish", indexedDate: today, title: "皿洗い", expiredAt: expiredAt),
        ]
        let sut = makeSUT(items: items)
        let expected = VoiceHouseworkPlan(
            title: "洗濯物干した",
            todayMatch: nil,
            todaySuggestions: ["洗濯物干し", "洗濯物たたみ"],
            suggestions: [],
            isNoteTooLong: false
        )

        // Act

        let actual = try await sut.voicePlan(title: "洗濯物干した", note: nil, now: now)

        // Assert

        #expect(actual == expected)
    }

    @Test("補足が無料プランで書ける文字数を超えていれば、聞き返す前に分かるよう返す")
    func voicePlanNoteTooLong() async throws {
        // Arrange

        let sut = makeSUT(items: [])
        let note = String(repeating: "あ", count: HouseworkMemoLimitPolicy.freeMaxCharacterCount + 1)
        let expected = VoiceHouseworkPlan(
            title: "買い物",
            todayMatch: nil,
            todaySuggestions: [],
            suggestions: [],
            isNoteTooLong: true
        )

        // Act

        let actual = try await sut.voicePlan(title: "買い物", note: note, now: now)

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - 記録

extension HouseworkIntentServiceVoiceTest {

    @Test("今日の家事に同じ名前の未完了の家事があれば、自分だけを担当者にして「ふつう」で完了にする")
    func recordTodayHousework() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯物干し",
            point: 20,
            expiredAt: expiredAt
        )
        let expectedItem = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯物干し",
            point: 20,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [item],
                frequentItems: [laundry],
                insertOrUpdateItem: { item in
                    // Assert

                    #expect(item == expectedItem)
                    confirmation()
                }
            )
            return try await sut.recordHousework(.frequent(id: laundry.id, title: laundry.title), now: now)
        }

        // Assert

        #expect(actual == .completed(title: "洗濯物干し", point: 20))
    }

    @Test("今日の家事に無いいつもの家事は、いつもの家事のポイントとメモで新しく作って完了にする")
    func recordFrequentHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "洗濯物干し",
            point: 30,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            createdAt: now,
            memo: .init(text: "タオルは外", checklist: [])
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                frequentItems: [laundry],
                insertOrUpdateItem: { item in
                    // Assert

                    #expect(item == expectedItem)
                    confirmation()
                }
            )
            return try await sut.recordHousework(.frequent(id: laundry.id, title: laundry.title), now: now)
        }

        // Assert

        #expect(actual == .completed(title: "洗濯物干し", point: 30))
    }

    @Test("名前だけの家事は、登録画面と同じ10ポイントで新しく作って完了にする")
    func recordNewHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "窓ふき",
            point: 10,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            createdAt: now
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                insertOrUpdateItem: { item in
                    // Assert

                    #expect(item == expectedItem)
                    confirmation()
                }
            )
            return try await sut.recordHousework(.title(" 窓ふき "), now: now)
        }

        // Assert

        #expect(actual == .completed(title: "窓ふき", point: 10))
    }

    @Test("選んだいつもの家事が消されていたら、名前だけの家事として記録する")
    func recordDeletedFrequentHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "洗濯物干し",
            point: 10,
            state: .completed,
            executorId: "own",
            effort: .normal,
            executedAt: now,
            expiredAt: expiredAt,
            createdAt: now
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                frequentItems: [],
                insertOrUpdateItem: { item in
                    // Assert

                    #expect(item == expectedItem)
                    confirmation()
                }
            )
            return try await sut.recordHousework(.frequent(id: laundry.id, title: laundry.title), now: now)
        }

        // Assert

        #expect(actual == .completed(title: "洗濯物干し", point: 10))
    }

    @Test("同じ名前の家事が今日はもう終わっている場合は、何も書き込まず終わっていることを返す")
    func recordAlreadyCompleted() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: "laundry",
            indexedDate: today,
            title: "洗濯物干し",
            state: .completed,
            executorId: "own",
            executedAt: now,
            expiredAt: expiredAt
        )
        let sut = makeSUT(
            items: [item],
            frequentItems: [laundry],
            insertOrUpdateItem: { _ in Issue.record("書き込まない") }
        )

        // Act

        let actual = try await sut.recordHousework(.frequent(id: laundry.id, title: laundry.title), now: now)

        // Assert

        #expect(actual == .alreadyCompleted(title: "洗濯物干し"))
    }

}

// MARK: - 登録

extension HouseworkIntentServiceVoiceTest {

    @Test("いつもの家事を、いつもの家事のメモの後ろに補足を足して今日の家事に登録する")
    func registerFrequentHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "洗濯物干し",
            point: 30,
            expiredAt: expiredAt,
            createdAt: now,
            memo: .init(text: "タオルは外\nシーツも", checklist: [])
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                frequentItems: [laundry],
                insertOrUpdateItems: { items in
                    // Assert

                    #expect(items == [expectedItem])
                    confirmation()
                }
            )
            return try await sut.registerHousework(
                .frequent(id: laundry.id, title: laundry.title),
                note: " シーツも ",
                now: now
            )
        }

        // Assert

        #expect(actual == .registered(title: "洗濯物干し"))
    }

    @Test("名前だけの家事は、補足をメモに入れて10ポイントで登録する")
    func registerNewHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "買い物",
            point: 10,
            expiredAt: expiredAt,
            createdAt: now,
            memo: .init(text: "牛乳と卵", checklist: [])
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                insertOrUpdateItems: { items in
                    // Assert

                    #expect(items == [expectedItem])
                    confirmation()
                }
            )
            return try await sut.registerHousework(.title("買い物"), note: "牛乳と卵", now: now)
        }

        // Assert

        #expect(actual == .registered(title: "買い物"))
    }

    @Test("同じ名前の未完了の家事が今日の家事にあれば、重ねて登録しない")
    func registerAlreadyRegistered() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(id: "shopping", indexedDate: today, title: "買い物", expiredAt: expiredAt)
        let sut = makeSUT(
            items: [item],
            insertOrUpdateItems: { _ in Issue.record("書き込まない") }
        )

        // Act

        let actual = try await sut.registerHousework(.title("買い物"), note: nil, now: now)

        // Assert

        #expect(actual == .alreadyRegistered(title: "買い物"))
    }

    @Test("同じ名前の家事が今日はもう終わっていれば、もう一度やる家事として登録する")
    func registerAgainAfterCompleted() async throws {
        // Arrange

        let item = HouseworkItem.makeForTest(
            id: "shopping",
            indexedDate: today,
            title: "買い物",
            state: .completed,
            executorId: "own",
            executedAt: now,
            expiredAt: expiredAt
        )
        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "買い物",
            point: 10,
            expiredAt: expiredAt,
            createdAt: now
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [item],
                insertOrUpdateItems: { items in
                    // Assert

                    #expect(items == [expectedItem])
                    confirmation()
                }
            )
            return try await sut.registerHousework(.title("買い物"), note: nil, now: now)
        }

        // Assert

        #expect(actual == .registered(title: "買い物"))
    }

    @Test("補足が無料プランで書ける文字数を超えていれば、登録しない")
    func registerMemoLimitExceeded() async throws {
        // Arrange

        let sut = makeSUT(
            items: [],
            insertOrUpdateItems: { _ in Issue.record("書き込まない") }
        )
        let note = String(repeating: "あ", count: HouseworkMemoLimitPolicy.freeMaxCharacterCount + 1)

        // Act

        let actual = try await sut.registerHousework(.title("買い物"), note: note, now: now)

        // Assert

        #expect(actual == .memoLimitExceeded)
    }

}

// MARK: - Analytics・プラン

extension HouseworkIntentServiceVoiceTest {

    @Test("新しく作って記録したときは、housework（complete）だけを送り、registerは送らない")
    func recordNewHouseworkAnalytics() async throws {
        // Arrange

        let logged = LoggedEvents()
        let sut = makeSUT(items: [], log: { logged.append($0) })

        // Act

        _ = try await sut.recordHousework(.title("窓ふき"), now: now)

        // Assert

        #expect(logged.value == [
            .housework(.complete(step: .appIntent, executorType: .ownOnly, effort: .normal, isSuccess: true)),
        ])
    }

    @Test(
        "登録したときは、いつもの家事ならsource=frequent、名前だけならsource=manualでregisterを送る",
        arguments: [
            (VoiceHouseworkTarget.frequent(id: "frequent-laundry", title: "洗濯物干し"), HouseworkRegisterSource.frequent),
            (.title("買い物"), .manual),
        ]
    )
    func registerAnalytics(target: VoiceHouseworkTarget, expectedSource: HouseworkRegisterSource) async throws {
        // Arrange

        let logged = LoggedEvents()
        let sut = makeSUT(items: [], frequentItems: [laundry], log: { logged.append($0) })

        // Act

        _ = try await sut.registerHousework(target, note: nil, now: now)

        // Assert

        #expect(logged.value == [.housework(.register(step: .appIntent, source: expectedSource, isSuccess: true))])
    }

    @Test("登録で選んだいつもの家事が消されていたら、名前だけの家事として10ポイント・メモ無しで登録する")
    func registerDeletedFrequentHousework() async throws {
        // Arrange

        let expectedItem = HouseworkItem.makeForTest(
            id: "new-id",
            indexedDate: today,
            title: "洗濯物干し",
            point: 10,
            expiredAt: expiredAt,
            createdAt: now
        )

        // Act

        let actual = try await confirmation { confirmation in
            let sut = makeSUT(
                items: [],
                frequentItems: [],
                insertOrUpdateItems: { items in
                    // Assert

                    #expect(items == [expectedItem])
                    confirmation()
                }
            )
            return try await sut.registerHousework(
                .frequent(id: laundry.id, title: laundry.title),
                note: nil,
                now: now
            )
        }

        // Assert

        #expect(actual == .registered(title: "洗濯物干し"))
    }

    @Test("プレミアムプランなら、無料プランの上限を超える補足でも登録する")
    func registerPremiumLongNote() async throws {
        // Arrange

        let premium = Account(id: "own", userName: "たろう", cohabitantId: "cohabitant", isPremium: true)
        let sut = makeSUT(items: [], account: premium)
        let note = String(repeating: "あ", count: HouseworkMemoLimitPolicy.freeMaxCharacterCount + 1)

        // Act

        let actual = try await sut.registerHousework(.title("買い物"), note: note, now: now)

        // Assert

        #expect(actual == .registered(title: "買い物"))
    }

    @Test("登録の書き込みがサーバーに届くのを待ちきれなければ、オンラインになったら反映されることを返す")
    func registerPendingSync() async throws {
        // Arrange

        var sut = makeSUT(
            items: [],
            // オフラインのFirestoreのように、サーバーの応答まで返らない
            insertOrUpdateItems: { _ in try await Task.sleep(for: .seconds(60)) }
        )
        sut.writeTimeout = .milliseconds(10)

        // Act

        let actual = try await sut.registerHousework(.title("買い物"), note: nil, now: now)

        // Assert

        #expect(actual == .pendingSync(title: "買い物"))
    }

}

/// 送ったAnalyticsイベントを集める
private final class LoggedEvents: @unchecked Sendable {

    private let lock = NSLock()
    private var events: [AnalyticsEvent] = []

    var value: [AnalyticsEvent] {
        lock.withLock { events }
    }

    func append(_ event: AnalyticsEvent) {
        lock.withLock { events.append(event) }
    }

}

private extension HouseworkIntentServiceVoiceTest {

    func makeSUT(
        items: [HouseworkItem],
        frequentItems: [FrequentHouseworkItem] = [],
        insertOrUpdateItem: @escaping @Sendable (HouseworkItem) async throws -> Void = { _ in },
        insertOrUpdateItems: @escaping @Sendable ([HouseworkItem]) async throws -> Void = { _ in },
        account: Account? = nil,
        log: @escaping @Sendable (AnalyticsEvent) -> Void = { _ in }
    ) -> HouseworkIntentService {
        let own = account ?? own
        let houseworkClient = HouseworkClient(
            insertOrUpdateItemHandler: { item, _ in try await insertOrUpdateItem(item) },
            insertOrUpdateItemsHandler: { items, _ in try await insertOrUpdateItems(items) },
            fetchItemsHandler: { _, _, _ in items }
        )
        let reminderUseCase = DailyCompletionReminderUseCase(client: .previewValue)
        var sut = HouseworkIntentService(
            sessionUseCase: .init(
                accountAuthClient: .init(currentAuth: { .init(id: "own") }),
                accountInfoClient: .init(fetch: { [own] id in id == own.id ? own : nil }),
                cohabitantClient: .init(),
                houseworkClient: houseworkClient,
                houseworkTemplateClient: .init(),
                frequentHouseworkClient: .init(addItemsSnapshotListener: { _, _ in
                    AsyncStream { $0.yield(frequentItems) }
                }),
                remoteConfigClient: .init(),
                currentAppVersion: "1.0.0"
            ),
            commandUseCase: .init(
                houseworkClient: houseworkClient,
                cohabitantPushNotificationClient: .previewValue,
                analyticsClient: .init(log: log),
                dailyCompletionReminderUseCase: reminderUseCase,
                calendar: .japanese
            ),
            dailyCompletionReminderUseCase: reminderUseCase,
            calendar: .japanese
        )
        sut.idGenerator = { "new-id" }
        return sut
    }

}
