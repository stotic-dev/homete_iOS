//
//  HouseworkAnalyticsExecutorTypeTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct HouseworkAnalyticsExecutorTypeTest {

    @Test(
        "操作した本人が担当者に含まれるかどうかで、担当者の組み合わせを判定する",
        arguments: [
            (["reporter"], HouseworkAnalyticsExecutorType.ownOnly),
            (["other"], .others),
            (["other", "another"], .others),
            (["reporter", "other"], .shared),
        ]
    )
    func init_executors_returnsType(
        userIds: [String],
        expected: HouseworkAnalyticsExecutorType
    ) {
        // Arrange
        let executors = userIds.map { HouseworkExecutor(userId: $0, percentage: 50, point: 1) }

        // Act
        let actual = HouseworkAnalyticsExecutorType(executors: executors, reporterId: "reporter")

        // Assert
        #expect(actual == expected)
    }

}
