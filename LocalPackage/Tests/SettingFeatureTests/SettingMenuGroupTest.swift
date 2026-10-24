//
//  SettingMenuGroupTest.swift
//  SettingFeatureTests
//

@testable import SettingFeature
import Testing

struct SettingMenuGroupTest {

    @Test("表示するメニューを、区分の表示順にまとめる")
    func make_groupsItemsInSectionOrder() {
        // Arrange

        let items: [SettingMenuItem] = [
            .memberInvitation,
            .taskTemplate,
            .frequentHousework,
            .notificationPermission,
            .premiumPlan,
            .termsOfService,
            .privacyPolicy,
            .license,
        ]

        // Act

        let actual = SettingMenuGroup.make(from: items)

        // Assert

        let expected: [SettingMenuGroup] = [
            .init(section: .group, items: [.memberInvitation]),
            .init(section: .housework, items: [.taskTemplate, .frequentHousework]),
            .init(section: .app, items: [.notificationPermission, .premiumPlan]),
            .init(section: .about, items: [.termsOfService, .privacyPolicy, .license]),
        ]
        #expect(actual == expected)
    }

    @Test("表示するメニューが無い区分は含めない")
    func make_excludesEmptySections() {
        // Arrange

        let items: [SettingMenuItem] = [
            .notificationPermission,
            .premiumPlan,
            .license,
        ]

        // Act

        let actual = SettingMenuGroup.make(from: items)

        // Assert

        let expected: [SettingMenuGroup] = [
            .init(section: .app, items: [.notificationPermission, .premiumPlan]),
            .init(section: .about, items: [.license]),
        ]
        #expect(actual == expected)
    }

}
