//
//  SettingMenuItemTest.swift
//  SettingFeatureTests
//

import Foundation
import HometeDomain
@testable import SettingFeature
import SwiftUI
import Testing

struct SettingMenuItemTest {

    @Test("未購入の場合、プレミアムプラン項目のタイトルは登録訴求文言になる")
    func title_premiumPlanFree_returnsPromotionTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.title(plan: .free)

        // Assert

        #expect(actual == "プレミアムプランに登録")
    }

    @Test("サブスクリプション購入済みの場合、プレミアムプラン項目のタイトルは登録済み文言になる")
    func title_premiumPlanSubscription_returnsRegisteredTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan
        let plan = SubscriptionPlan.subscription(period: .monthly, nextRenewalDate: .now)

        // Act

        let actual = sut.title(plan: plan)

        // Assert

        #expect(actual == "ご登録中のプラン")
    }

    @Test("買い切り購入済みの場合、プレミアムプラン項目のタイトルは登録済み文言になる")
    func title_premiumPlanLifetime_returnsRegisteredTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.title(plan: .lifetime)

        // Assert

        #expect(actual == "ご登録中のプラン")
    }

    @Test(
        "プレミアムプラン以外の項目はプラン状態に関わらず固定タイトルを返す",
        arguments: [
            (SettingMenuItem.memberRegistration, "メンバー追加"),
            (SettingMenuItem.taskTemplate, "家事テンプレート"),
            (SettingMenuItem.termsOfService, "利用規約"),
            (SettingMenuItem.privacyPolicy, "プライバシーポリシー"),
            (SettingMenuItem.license, "ライセンス"),
        ] as [(SettingMenuItem, String)]
    )
    func title_notPremiumPlanItem_returnsFixedTitleRegardlessOfPlan(
        item: SettingMenuItem,
        expectedTitle: String
    ) {
        // Arrange
        // Act

        let actual = item.title(plan: .lifetime)

        // Assert

        #expect(actual == LocalizedStringKey(expectedTitle))
    }

    @Test("未購入の場合、プレミアムプラン項目は有効になる")
    func isEnabled_premiumPlanFree_returnsTrue() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.isEnabled(plan: .free)

        // Assert

        #expect(actual == true)
    }

    @Test("サブスクリプション購入済みの場合、プレミアムプラン項目は有効になる")
    func isEnabled_premiumPlanSubscription_returnsTrue() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan
        let plan = SubscriptionPlan.subscription(period: .yearly, nextRenewalDate: .now)

        // Act

        let actual = sut.isEnabled(plan: plan)

        // Assert

        #expect(actual == true)
    }

    @Test("買い切り購入済みの場合、プラン更新の導線を閉じるためプレミアムプラン項目は無効になる")
    func isEnabled_premiumPlanLifetime_returnsFalse() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.isEnabled(plan: .lifetime)

        // Assert

        #expect(actual == false)
    }

    @Test(
        "プレミアムプラン以外の項目は買い切り購入済みでも常に有効になる",
        arguments: [
            SettingMenuItem.memberRegistration,
            .taskTemplate,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]
    )
    func isEnabled_notPremiumPlanItem_lifetimePlan_returnsTrue(item: SettingMenuItem) {
        // Arrange
        // Act

        let actual = item.isEnabled(plan: .lifetime)

        // Assert

        #expect(actual == true)
    }

    @Test("グループ参加済みの場合、家事テンプレート項目を含む表示項目が返る")
    func displayItems_registeredGroup_includesTaskTemplate() {
        // Arrange

        let expected: [SettingMenuItem] = [
            .memberRegistration,
            .taskTemplate,
            .premiumPlan,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]

        // Act

        let actual = SettingMenuItem.displayItems(true)

        // Assert

        #expect(actual == expected)
    }

    @Test("グループ未参加の場合、家事テンプレート項目を除いた表示項目が返る")
    func displayItems_notRegisteredGroup_excludesTaskTemplate() {
        // Arrange

        let expected: [SettingMenuItem] = [
            .memberRegistration,
            .premiumPlan,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]

        // Act

        let actual = SettingMenuItem.displayItems(false)

        // Assert

        #expect(actual == expected)
    }

}
