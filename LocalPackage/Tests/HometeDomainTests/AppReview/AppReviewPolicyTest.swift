// swiftlint:disable file_length
//
//  AppReviewPolicyTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

enum AppReviewPolicyTest {

    struct InitCase {}
    struct PurchaseTriggerCase {}
    struct ReceiveThanksCase {}
    struct MarkRequestedCase {}

}

// MARK: - 初期化

extension AppReviewPolicyTest.InitCase {

    @Test("保存した記録が無い場合、今の日時から使い始めたものとして記録を作る")
    func init_noSavedState_startsNow() {
        // Arrange

        let now = AppReviewPolicyTest.baseDate
        let expected = AppReviewState(
            startedAt: now,
            thanksCountedUntil: now,
            receivedThanksCount: 0,
            requestedTriggers: [],
            lastRequestedAt: nil
        )

        // Act

        let sut = AppReviewPolicy(savedState: nil, now: now)

        // Assert

        #expect(sut.state == expected)
    }

    @Test("保存した記録がある場合、その記録を引き継ぐ")
    func init_savedState_keepsSavedState() {
        // Arrange

        let savedState = AppReviewState(
            startedAt: AppReviewPolicyTest.baseDate,
            thanksCountedUntil: AppReviewPolicyTest.date(afterDays: 1),
            receivedThanksCount: 3,
            requestedTriggers: [.purchase],
            lastRequestedAt: AppReviewPolicyTest.date(afterDays: 2)
        )

        // Act

        let sut = AppReviewPolicy(savedState: savedState, now: AppReviewPolicyTest.date(afterDays: 5))

        // Assert

        #expect(sut.state == savedState)
    }

}

// MARK: - 課金

extension AppReviewPolicyTest.PurchaseTriggerCase {

    @Test("取得済みの無料プランからプレミアムプランに変わった場合、課金をきっかけにする")
    func purchaseTrigger_freeToPremium_returnsPurchase() {
        // Arrange

        let sut = AppReviewPolicy(savedState: nil, now: AppReviewPolicyTest.baseDate)

        // Act

        let actual = sut.purchaseTrigger(
            from: AppReviewPolicyTest.entitlement(isActive: false),
            to: AppReviewPolicyTest.entitlement(isActive: true),
            now: AppReviewPolicyTest.baseDate
        )

        // Assert

        #expect(actual == .purchase)
    }

    @Test(
        "無料プランからプレミアムプランに変わっていない場合、きっかけにしない",
        arguments: [
            (old: nil, new: true),
            (old: true, new: true),
            (old: false, new: false),
            (old: true, new: false),
            (old: false, new: nil),
        ] as [(old: Bool?, new: Bool?)]
    )
    func purchaseTrigger_notFreeToPremium_returnsNil(old: Bool?, new: Bool?) {
        // Arrange

        let sut = AppReviewPolicy(savedState: nil, now: AppReviewPolicyTest.baseDate)

        // Act

        let actual = sut.purchaseTrigger(
            from: old.map { AppReviewPolicyTest.entitlement(isActive: $0) },
            to: new.map { AppReviewPolicyTest.entitlement(isActive: $0) },
            now: AppReviewPolicyTest.baseDate
        )

        // Assert

        #expect(actual == nil)
    }

    @Test("課金をきっかけにリクエスト済みの場合、きっかけにしない")
    func purchaseTrigger_alreadyRequested_returnsNil() {
        // Arrange

        let sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(
                requestedTriggers: [.purchase],
                lastRequestedAt: AppReviewPolicyTest.baseDate
            ),
            now: AppReviewPolicyTest.baseDate
        )

        // Act

        let actual = sut.purchaseTrigger(
            from: AppReviewPolicyTest.entitlement(isActive: false),
            to: AppReviewPolicyTest.entitlement(isActive: true),
            now: AppReviewPolicyTest.date(afterDays: 60)
        )

        // Assert

        #expect(actual == nil)
    }

    @Test(
        "前回のリクエストからの日数で、課金をきっかけにするかが変わる",
        arguments: [
            (days: 29, expected: nil),
            (days: 30, expected: .purchase),
        ] as [(days: Double, expected: AppReviewTrigger?)]
    )
    func purchaseTrigger_requestInterval(days: Double, expected: AppReviewTrigger?) {
        // Arrange

        let sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(
                requestedTriggers: [.thanksCount],
                lastRequestedAt: AppReviewPolicyTest.baseDate
            ),
            now: AppReviewPolicyTest.baseDate
        )

        // Act

        let actual = sut.purchaseTrigger(
            from: AppReviewPolicyTest.entitlement(isActive: false),
            to: AppReviewPolicyTest.entitlement(isActive: true),
            now: AppReviewPolicyTest.date(afterDays: days)
        )

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - ありがとう

extension AppReviewPolicyTest.ReceiveThanksCase {

    @Test("自分が担当した家事に自分以外から届いた新しいありがとうを数え、数えた中で一番新しい日時まで進める")
    func receiveThanks_newThanks_countsAndAdvances() {
        // Arrange

        var sut = AppReviewPolicy(savedState: nil, now: AppReviewPolicyTest.baseDate)
        let items = AppReviewPolicyTest.houseworkList([
            AppReviewPolicyTest.completedItem(
                id: 1,
                executorId: AppReviewPolicyTest.accountId,
                thanks: [
                    "partner1": AppReviewPolicyTest.thanks(afterDays: 1),
                    "partner2": AppReviewPolicyTest.thanks(afterDays: 2),
                ]
            ),
        ])
        let expected = AppReviewState(
            startedAt: AppReviewPolicyTest.baseDate,
            thanksCountedUntil: AppReviewPolicyTest.date(afterDays: 2),
            receivedThanksCount: 2,
            requestedTriggers: [],
            lastRequestedAt: nil
        )

        // Act

        let actual = sut.receiveThanks(
            in: items,
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 3)
        )

        // Assert

        #expect(actual == nil)
        #expect(sut.state == expected)
    }

    @Test("数え始める前のありがとう・自分が担当していない家事のありがとう・自分が送ったありがとうは数えない")
    func receiveThanks_notTargetThanks_doesNotCount() {
        // Arrange

        let savedState = AppReviewPolicyTest.state(thanksCountedUntil: AppReviewPolicyTest.date(afterDays: 1))
        var sut = AppReviewPolicy(savedState: savedState, now: AppReviewPolicyTest.baseDate)
        let items = AppReviewPolicyTest.houseworkList([
            AppReviewPolicyTest.completedItem(
                id: 1,
                executorId: AppReviewPolicyTest.accountId,
                thanks: ["partner": AppReviewPolicyTest.thanks(afterDays: 1)]
            ),
            AppReviewPolicyTest.completedItem(
                id: 2,
                executorId: "partner",
                thanks: [AppReviewPolicyTest.accountId: AppReviewPolicyTest.thanks(afterDays: 2)]
            ),
            AppReviewPolicyTest.completedItem(
                id: 3,
                executorId: AppReviewPolicyTest.accountId,
                thanks: [AppReviewPolicyTest.accountId: AppReviewPolicyTest.thanks(afterDays: 2)]
            ),
        ])

        // Act

        let actual = sut.receiveThanks(
            in: items,
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 3)
        )

        // Assert

        #expect(actual == nil)
        #expect(sut.state == savedState)
    }

    @Test("受け取ったありがとうの合計が10回になった場合、合計をきっかけにする")
    func receiveThanks_reachesThreshold_returnsThanksCount() {
        // Arrange

        var sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(receivedThanksCount: 9),
            now: AppReviewPolicyTest.baseDate
        )

        // Act

        let actual = sut.receiveThanks(
            in: AppReviewPolicyTest.oneNewThanksList(afterDays: 1),
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 1)
        )

        // Assert

        #expect(actual == .thanksCount)
    }

    @Test(
        "使い始めてからの日数で、ありがとうをきっかけにするかが変わる",
        arguments: [
            (days: 13, expected: nil),
            (days: 14, expected: .thanksAfterTwoWeeks),
        ] as [(days: Double, expected: AppReviewTrigger?)]
    )
    func receiveThanks_usagePeriod(days: Double, expected: AppReviewTrigger?) {
        // Arrange

        var sut = AppReviewPolicy(savedState: nil, now: AppReviewPolicyTest.baseDate)

        // Act

        let actual = sut.receiveThanks(
            in: AppReviewPolicyTest.oneNewThanksList(afterDays: days),
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: days)
        )

        // Assert

        #expect(actual == expected)
    }

    @Test("合計と使い始めてからの日数の両方を満たした場合、合計を優先する")
    func receiveThanks_bothSatisfied_prefersThanksCount() {
        // Arrange

        var sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(receivedThanksCount: 9),
            now: AppReviewPolicyTest.baseDate
        )

        // Act

        let actual = sut.receiveThanks(
            in: AppReviewPolicyTest.oneNewThanksList(afterDays: 14),
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 14)
        )

        // Assert

        #expect(actual == .thanksCount)
    }

    @Test("合計をきっかけにリクエスト済みの場合、使い始めてからの日数をきっかけにする")
    func receiveThanks_thanksCountRequested_returnsThanksAfterTwoWeeks() {
        // Arrange

        var sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(
                receivedThanksCount: 10,
                requestedTriggers: [.thanksCount],
                lastRequestedAt: AppReviewPolicyTest.baseDate
            ),
            now: AppReviewPolicyTest.baseDate
        )

        // Act

        let actual = sut.receiveThanks(
            in: AppReviewPolicyTest.oneNewThanksList(afterDays: 30),
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 30)
        )

        // Assert

        #expect(actual == .thanksAfterTwoWeeks)
    }

    @Test("前回のリクエストから30日たっていない場合、条件を満たしてもきっかけにせず数えるだけにする")
    func receiveThanks_withinRequestInterval_returnsNilAndCounts() {
        // Arrange

        var sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(
                receivedThanksCount: 9,
                requestedTriggers: [.purchase],
                lastRequestedAt: AppReviewPolicyTest.date(afterDays: 1)
            ),
            now: AppReviewPolicyTest.baseDate
        )
        let expected = AppReviewPolicyTest.state(
            thanksCountedUntil: AppReviewPolicyTest.date(afterDays: 20),
            receivedThanksCount: 10,
            requestedTriggers: [.purchase],
            lastRequestedAt: AppReviewPolicyTest.date(afterDays: 1)
        )

        // Act

        let actual = sut.receiveThanks(
            in: AppReviewPolicyTest.oneNewThanksList(afterDays: 20),
            accountId: AppReviewPolicyTest.accountId,
            now: AppReviewPolicyTest.date(afterDays: 20)
        )

        // Assert

        #expect(actual == nil)
        #expect(sut.state == expected)
    }

}

// MARK: - リクエストの記録

extension AppReviewPolicyTest.MarkRequestedCase {

    @Test("リクエストしたきっかけと日時を記録する")
    func markRequested_recordsTriggerAndDate() {
        // Arrange

        var sut = AppReviewPolicy(
            savedState: AppReviewPolicyTest.state(
                requestedTriggers: [.purchase],
                lastRequestedAt: AppReviewPolicyTest.baseDate
            ),
            now: AppReviewPolicyTest.baseDate
        )
        let expected = AppReviewPolicyTest.state(
            requestedTriggers: [.purchase, .thanksCount],
            lastRequestedAt: AppReviewPolicyTest.date(afterDays: 40)
        )

        // Act

        sut.markRequested(.thanksCount, now: AppReviewPolicyTest.date(afterDays: 40))

        // Assert

        #expect(sut.state == expected)
    }

}

// MARK: - Helper

private extension AppReviewPolicyTest {

    static let accountId = "me"
    static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func date(afterDays days: Double) -> Date {
        baseDate.addingTimeInterval(days * 24 * 60 * 60)
    }

    static func state(
        thanksCountedUntil: Date = baseDate,
        receivedThanksCount: Int = 0,
        requestedTriggers: Set<AppReviewTrigger> = [],
        lastRequestedAt: Date? = nil
    ) -> AppReviewState {
        .init(
            startedAt: baseDate,
            thanksCountedUntil: thanksCountedUntil,
            receivedThanksCount: receivedThanksCount,
            requestedTriggers: requestedTriggers,
            lastRequestedAt: lastRequestedAt
        )
    }

    static func entitlement(isActive: Bool) -> EntitlementInfo {
        .init(isActive: isActive, productIdentifier: "premium_monthly", expirationDate: nil, willRenew: isActive)
    }

    static func thanks(afterDays days: Double) -> HouseworkThanks {
        .init(comment: nil, sentAt: date(afterDays: days))
    }

    static func completedItem(id: Int, executorId: String, thanks: [String: HouseworkThanks]) -> HouseworkItem {
        .makeForTest(id: id, indexedDate: baseDate, state: .completed, executorId: executorId, thanks: thanks)
    }

    static func houseworkList(_ items: [HouseworkItem]) -> StoredAllHouseworkList {
        .init(value: [.makeForTest(items: items)])
    }

    /// 自分が担当した家事に、同居人から新しいありがとうが1件届いた一覧
    static func oneNewThanksList(afterDays days: Double) -> StoredAllHouseworkList {
        houseworkList([
            completedItem(id: 1, executorId: accountId, thanks: ["partner": thanks(afterDays: days)]),
        ])
    }

}
