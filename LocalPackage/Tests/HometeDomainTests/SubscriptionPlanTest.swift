//
//  SubscriptionPlanTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

struct SubscriptionPlanTest {

    @Test("未購入の場合、planはfreeになる")
    func plan_notActive_returnsFree() {
        // Arrange

        let sut = EntitlementInfo(
            isActive: false,
            productIdentifier: "",
            expirationDate: nil,
            willRenew: false
        )

        // Act

        let actual = sut.plan

        // Assert

        #expect(actual == .free)
    }

    @Test("購入済みの場合、planはsubscriptionになる")
    func plan_active_returnsSubscription() {
        // Arrange

        let expirationDate = Date(timeIntervalSince1970: 1_700_000_000)
        let sut = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: expirationDate,
            willRenew: true
        )

        // Act

        let actual = sut.plan

        // Assert

        let expected = SubscriptionPlan.subscription(
            period: .monthly,
            nextRenewalDate: expirationDate,
            willRenew: true
        )
        #expect(actual == expected)
    }

    @Test("解約済みの場合、planのwillRenewはfalseになる")
    func plan_activeAndNotWillRenew_returnsSubscriptionWithoutRenewal() {
        // Arrange

        let expirationDate = Date(timeIntervalSince1970: 1_700_000_000)
        let sut = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_yearly",
            expirationDate: expirationDate,
            willRenew: false
        )

        // Act

        let actual = sut.plan

        // Assert

        let expected = SubscriptionPlan.subscription(
            period: .yearly,
            nextRenewalDate: expirationDate,
            willRenew: false
        )
        #expect(actual == expected)
    }

    @Test("有効期限が取得できない場合でも、購入済みならplanはsubscriptionになる")
    func plan_activeWithoutExpirationDate_returnsSubscriptionWithNilRenewalDate() {
        // Arrange

        let sut = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )

        // Act

        let actual = sut.plan

        // Assert

        let expected = SubscriptionPlan.subscription(
            period: .monthly,
            nextRenewalDate: nil,
            willRenew: true
        )
        #expect(actual == expected)
    }

    @Test(
        "自動更新されるかどうかがplanの状態から判定される",
        arguments: [
            (SubscriptionPlan.subscription(period: .monthly, nextRenewalDate: nil, willRenew: true), true),
            (SubscriptionPlan.subscription(period: .monthly, nextRenewalDate: nil, willRenew: false), false),
            (SubscriptionPlan.free, false),
        ]
    )
    func willAutoRenew_returnsExpectedResult(plan: SubscriptionPlan, expected: Bool) {
        // Arrange
        // Act

        let actual = plan.willAutoRenew

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "プロダクトIDに含まれるキーワードから周期が判定される",
        arguments: [
            ("premium_monthly", SubscriptionPeriod.monthly),
            ("premium_yearly", SubscriptionPeriod.yearly),
            ("premium_annual", SubscriptionPeriod.yearly),
            ("premium_unknown_plan", SubscriptionPeriod.unknown),
        ]
    )
    func subscriptionPeriod_fromProductIdentifier_returnsExpectedPeriod(
        productIdentifier: String,
        expectedPeriod: SubscriptionPeriod
    ) {
        // Arrange
        // Act

        let actual = SubscriptionPeriod(productIdentifier: productIdentifier)

        // Assert

        #expect(actual == expectedPeriod)
    }

}
