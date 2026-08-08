//
//  SettingMenuItemTest.swift
//  SettingFeatureTests
//

@testable import SettingFeature
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
        "プレミアムプラン以外の項目は購入状態に関わらずタイトルが変化しない",
        arguments: [
            SettingMenuItem.memberRegistration,
            .taskTemplate,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]
    )
    func title_notPremiumPlanItem_titleIsUnaffectedByIsPremium(item: SettingMenuItem) {
        // Arrange
        // Act

        let notPremiumTitle = item.title(isPremium: false)
        let premiumTitle = item.title(isPremium: true)

        // Assert

        #expect(notPremiumTitle == premiumTitle)
    }

    @Test("プレミアムプラン項目は常に表示対象に含まれる")
    func displayItems_containsPremiumPlan() {
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

}
