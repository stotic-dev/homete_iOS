//
//  CohabitantRegistrationRoleTests.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct CohabitantRegistrationRoleTests {

    @Test(
        "リーダーかどうかを判定できること",
        arguments: [
            (CohabitantRegistrationRole.lead, true),
            (.follower, false),
        ]
    )
    func isLeader(role: CohabitantRegistrationRole, expected: Bool) {
        // Act
        let actual = role.isLeader

        // Assert
        #expect(actual == expected)
    }

}
