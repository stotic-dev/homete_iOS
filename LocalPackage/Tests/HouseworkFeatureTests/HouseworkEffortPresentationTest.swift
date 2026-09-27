//
//  HouseworkEffortPresentationTest.swift
//  LocalPackage
//

import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkEffortPresentationTest {

    @Test(
        "上乗せしたときは上乗せ前後のポイントの内訳を返し、ふつうでは返さない",
        arguments: [
            (HouseworkEffort.normal, nil),
            (HouseworkEffort.hard, "10pt → 12pt"),
            (HouseworkEffort.veryHard, "10pt → 15pt"),
        ] as [(HouseworkEffort, String?)]
    )
    func pointBreakdown(effort: HouseworkEffort, expected: String?) {
        // Act
        let result = effort.pointBreakdown(basePoint: 10)

        // Assert
        #expect(result == expected)
    }

}
