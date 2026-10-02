//
//  ForceUpdateRequirementTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct ForceUpdateRequirementTest {

    @Test("現在のバージョンが最低バージョンを下回る場合、強制アップデートが必要になる")
    func olderThanMinimumRequiresUpdate() {
        // Act

        let requirement = ForceUpdateRequirement.make(
            currentVersion: "1.9.0",
            minimumRequiredVersion: "1.10.0",
            message: ""
        )

        // Assert

        #expect(requirement == .init(message: nil))
    }

    @Test("案内文言が設定されている場合は、前後の空白を除いて持つ")
    func messageIsTrimmed() {
        // Act

        let requirement = ForceUpdateRequirement.make(
            currentVersion: "1.0.0",
            minimumRequiredVersion: "2.0.0",
            message: "  不具合を修正しました\n"
        )

        // Assert

        #expect(requirement == .init(message: "不具合を修正しました"))
    }

    @Test(
        "現在のバージョンが最低バージョン以上の場合、強制アップデートは不要",
        arguments: [
            ("1.10.0", "1.10.0"),
            ("1.10.0", "1.9.0"),
            ("1.4.0", "1.4"),
        ]
    )
    func notOlderThanMinimumDoesNotRequireUpdate(current: String, minimum: String) {
        // Act

        let requirement = ForceUpdateRequirement.make(
            currentVersion: current,
            minimumRequiredVersion: minimum,
            message: "案内"
        )

        // Assert

        #expect(requirement == nil)
    }

    @Test(
        "どちらかのバージョンが未設定・不正な値の場合は、締め出さないよう強制アップデートを不要とする",
        arguments: [
            ("1.0.0", ""),
            ("1.0.0", "2.0.0-beta"),
            ("", "2.0.0"),
            ("abc", "2.0.0"),
        ]
    )
    func invalidVersionDoesNotRequireUpdate(current: String, minimum: String) {
        // Act

        let requirement = ForceUpdateRequirement.make(
            currentVersion: current,
            minimumRequiredVersion: minimum,
            message: "案内"
        )

        // Assert

        #expect(requirement == nil)
    }

}
