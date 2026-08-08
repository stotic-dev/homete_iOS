//
//  SettingMenuItemTest.swift
//  SettingFeatureTests
//

@testable import SettingFeature
import SwiftUI
import Testing

struct SettingMenuItemTest {

    @Test("未購入の場合、プレミアムプラン項目のタイトルは登録訴求文言になる")
    func title_premiumPlanNotPremium_returnsPromotionTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.title(isPremium: false)

        // Assert

        #expect(actual == "プレミアムプランに登録")
    }

    @Test("購入済みの場合、プレミアムプラン項目のタイトルは登録済み文言になる")
    func title_premiumPlanIsPremium_returnsRegisteredTitle() {
        // Arrange

        let sut = SettingMenuItem.premiumPlan

        // Act

        let actual = sut.title(isPremium: true)

        // Assert

        #expect(actual == "ご登録中のプラン")
    }

    @Test(
        "プレミアムプラン以外の項目は未購入時に固定タイトルを返す",
        arguments: [
            (SettingMenuItem.memberRegistration, "メンバー追加"),
            (SettingMenuItem.taskTemplate, "家事テンプレート"),
            (SettingMenuItem.termsOfService, "利用規約"),
            (SettingMenuItem.privacyPolicy, "プライバシーポリシー"),
            (SettingMenuItem.license, "ライセンス"),
        ] as [(SettingMenuItem, String)]
    )
    func title_notPremiumPlanItem_isPremiumFalse_returnsFixedTitle(
        item: SettingMenuItem,
        expectedTitle: String
    ) {
        // Arrange
        // Act

        let actual = item.title(isPremium: false)

        // Assert

        #expect(actual == LocalizedStringKey(expectedTitle))
    }

    @Test(
        "プレミアムプラン以外の項目は購入済み時も固定タイトルを返す",
        arguments: [
            (SettingMenuItem.memberRegistration, "メンバー追加"),
            (SettingMenuItem.taskTemplate, "家事テンプレート"),
            (SettingMenuItem.termsOfService, "利用規約"),
            (SettingMenuItem.privacyPolicy, "プライバシーポリシー"),
            (SettingMenuItem.license, "ライセンス"),
        ] as [(SettingMenuItem, String)]
    )
    func title_notPremiumPlanItem_isPremiumTrue_returnsFixedTitle(
        item: SettingMenuItem,
        expectedTitle: String
    ) {
        // Arrange
        // Act

        let actual = item.title(isPremium: true)

        // Assert

        #expect(actual == LocalizedStringKey(expectedTitle))
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
