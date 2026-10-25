//
//  AppAvailabilityTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct AppAvailabilityTest {

    @Test(
        "メンテナンス中かどうかと強制アップデートの要否から、利用を止める理由を決める。両方ならメンテナンスを優先する",
        arguments: [
            (true, true, AppAvailability.underMaintenance),
            (true, false, .underMaintenance),
            (false, true, .updateRequired),
            (false, false, .available),
        ]
    )
    func initialize(isUnderMaintenance: Bool, isForceUpdateRequired: Bool, expected: AppAvailability) {
        // Act

        let actual = AppAvailability(
            isUnderMaintenance: isUnderMaintenance,
            isForceUpdateRequired: isForceUpdateRequired
        )

        // Assert

        #expect(actual == expected)
    }

}
