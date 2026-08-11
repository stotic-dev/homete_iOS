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
        let plan = SubscriptionPlan.subscription(
            period: .monthly,
            nextRenewalDate: .now,
            willRenew: true
        )

        // Act

        let actual = sut.title(plan: plan)

        // Assert

        #expect(actual == "ご登録中のプラン")
    }

    @Test("解約済みのサブスクリプションでも、プレミアムプラン項目のタイトルは登録済み文言になる")
    func title_premiumPlanCanceledSubscription_returnsRegisteredTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan
        let plan = SubscriptionPlan.subscription(
            period: .yearly,
            nextRenewalDate: .now,
            willRenew: false
        )

        // Act

        let actual = sut.title(plan: plan)

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

        let plan = SubscriptionPlan.subscription(
            period: .monthly,
            nextRenewalDate: .now,
            willRenew: true
        )

        // Act

        let actual = item.title(plan: plan)

        // Assert

        #expect(actual == LocalizedStringKey(expectedTitle))
    }

    @Test("グループ参加済みの場合、家事テンプレート項目を含む表示項目が返る")
    func displayItems_registeredGroup_includesTaskTemplate() {
        // Arrange

        var expected: [SettingMenuItem] = [
            .memberRegistration,
            .taskTemplate,
            .premiumPlan,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]
        // デバッグメニュー項目はDEBUGビルドにのみ存在する
        #if DEBUG
        expected.append(.debugMenu)
        #endif

        // Act

        let actual = SettingMenuItem.displayItems(true)

        // Assert

        #expect(actual == expected)
    }

    @Test("グループ未参加の場合、家事テンプレート項目を除いた表示項目が返る")
    func displayItems_notRegisteredGroup_excludesTaskTemplate() {
        // Arrange

        var expected: [SettingMenuItem] = [
            .memberRegistration,
            .premiumPlan,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]
        // デバッグメニュー項目はDEBUGビルドにのみ存在する
        #if DEBUG
        expected.append(.debugMenu)
        #endif

        // Act

        let actual = SettingMenuItem.displayItems(false)

        // Assert

        #expect(actual == expected)
    }

}
