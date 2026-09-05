//
//  CohabitantInvitationErrorTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct CohabitantInvitationErrorTest {

    @Test(
        "招待固有のサーバコードは対応するエラーに変換される",
        arguments: [
            ("invitation-not-found", CohabitantInvitationError.notFound),
            ("cohabitant-not-found", CohabitantInvitationError.notFound),
            ("invitation-expired", CohabitantInvitationError.expired),
            ("already-joined", CohabitantInvitationError.alreadyJoined),
        ]
    )
    func init_withInvitationServerCode(serverCode: String, expected: CohabitantInvitationError) {
        // Act
        let actual = CohabitantInvitationError(serverCode: serverCode)

        // Assert
        #expect(actual == expected)
    }

    @Test(
        "招待固有でないサーバコードはnilになる",
        arguments: ["account-not-found", "unknown-code", ""]
    )
    func init_withOtherServerCode(serverCode: String) {
        // Act
        let actual = CohabitantInvitationError(serverCode: serverCode)

        // Assert
        #expect(actual == nil)
    }

}
