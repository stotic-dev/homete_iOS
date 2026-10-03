//
//  ForceUpdatePolicyTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct ForceUpdatePolicyTest {

    @Test("現在のバージョンが最低バージョンを下回る場合、強制アップデートが必要になる")
    func olderThanMinimumRequiresUpdate() {
        // Act

        let isRequired = ForceUpdatePolicy.isRequired(
            currentVersion: "1.9.0",
            minimumRequiredVersion: "1.10.0"
        )

        // Assert

        #expect(isRequired == true)
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

        let isRequired = ForceUpdatePolicy.isRequired(
            currentVersion: current,
            minimumRequiredVersion: minimum
        )

        // Assert

        #expect(isRequired == false)
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

        let isRequired = ForceUpdatePolicy.isRequired(
            currentVersion: current,
            minimumRequiredVersion: minimum
        )

        // Assert

        #expect(isRequired == false)
    }

}
