//
//  AnalyticsUserPropertyTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct AnalyticsUserPropertyTest {

    @Test(
        "ユーザープロパティを、GA4に送信するname/valueの組に変換する",
        arguments: [
            (AnalyticsUserProperty.isPremium(true), "is_premium", "true"),
            (AnalyticsUserProperty.isPremium(false), "is_premium", "false"),
            (AnalyticsUserProperty.hasCohabitant(true), "has_cohabitant", "true"),
            (AnalyticsUserProperty.hasCohabitant(false), "has_cohabitant", "false"),
            (AnalyticsUserProperty.cohabitantMemberCount(2), "cohabitant_member_count", "2"),
        ]
    )
    func nameAndValue(property: AnalyticsUserProperty, expectedName: String, expectedValue: String) {
        #expect(property.name == expectedName)
        #expect(property.value == expectedValue)
    }

}
