//
//  WelcomeInvitationStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct WelcomeInvitationStoreTest {

    @Test("招待の概要を取得できたら、招待者名つきの案内を出す")
    func load_success() async {
        // Arrange
        let sut = WelcomeInvitationStore(
            cohabitantInvitationClient: .init(fetch: { token in
                #expect(token == "test-token")
                return .init(inviterName: "たろう", expiresAt: Date(timeIntervalSince1970: 100))
            })
        )

        // Act
        await sut.load(token: "test-token")

        // Assert
        #expect(sut.invitation == .invited(inviterName: "たろう"))
    }

    @Test(
        "招待者の名前が無い・空のときは、名前なしの案内を出す",
        arguments: [nil, ""] as [String?]
    )
    func load_noInviterName(inviterName: String?) async {
        // Arrange
        let sut = WelcomeInvitationStore(
            cohabitantInvitationClient: .init(fetch: { _ in
                .init(inviterName: inviterName, expiresAt: Date(timeIntervalSince1970: 100))
            })
        )

        // Act
        await sut.load(token: "test-token")

        // Assert
        #expect(sut.invitation == .invited(inviterName: nil))
    }

    @Test(
        "取得に失敗した・無効な招待のときは、案内を出さない",
        arguments: [
            CohabitantInvitationError.notFound,
            CohabitantInvitationError.expired,
            DomainError.noNetwork,
        ] as [any Error]
    )
    func load_failure(error: any Error) async {
        // Arrange
        let sut = WelcomeInvitationStore(
            cohabitantInvitationClient: .init(fetch: { _ in throw error })
        )

        // Act
        await sut.load(token: "test-token")

        // Assert
        #expect(sut.invitation == .none)
    }

    @Test("招待トークンが無いときは、取得せずに案内を出さない")
    func load_noToken() async {
        // Arrange
        let sut = WelcomeInvitationStore(
            cohabitantInvitationClient: .init(fetch: { _ in
                Issue.record()
                return .preview
            })
        )

        // Act
        await sut.load(token: nil)

        // Assert
        #expect(sut.invitation == .none)
    }

}
