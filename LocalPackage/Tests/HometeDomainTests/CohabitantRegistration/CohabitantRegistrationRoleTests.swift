//
//  CohabitantRegistrationRoleTests.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

struct CohabitantRegistrationRoleTests {

    @Test("フォロワーの場合、アカウントIDが取得できること")
    func accountId_follower() {
        // Arrange
        let role = CohabitantRegistrationRole.follower(accountId: "id")

        // Act
        let actual = role.accountId

        // Assert
        #expect(actual == "id")
    }

    @Test("リーダーの場合、アカウントIDはnilを返す")
    func accountId_lead() {
        // Arrange
        let role = CohabitantRegistrationRole.lead

        // Act
        let actual = role.accountId

        // Assert
        #expect(actual == nil)
    }

}
