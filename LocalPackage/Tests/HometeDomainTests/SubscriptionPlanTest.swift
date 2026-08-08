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

        let sut = EntitlementInfo(isActive: false, productIdentifier: "", expirationDate: nil)

        // Act

        let actual = sut.plan

        // Assert

        #expect(actual == .free)
    }

    @Test("有効期限がある場合、planはsubscriptionになる")
    func plan_activeWithExpirationDate_returnsSubscription() {
        // Arrange

        let expirationDate = Date(timeIntervalSince1970: 1_700_000_000)
        let sut = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: expirationDate
        )

        // Act

        let actual = sut.plan

        // Assert

        let expected = SubscriptionPlan.subscription(period: .monthly, nextRenewalDate: expirationDate)
        #expect(actual == expected)
    }

    @Test("有効期限がない場合、planはlifetimeになる")
    func plan_activeWithoutExpirationDate_returnsLifetime() {
        // Arrange

        let sut = EntitlementInfo(isActive: true, productIdentifier: "premium_lifetime", expirationDate: nil)

        // Act

        let actual = sut.plan

        // Assert

        #expect(actual == .lifetime)
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
