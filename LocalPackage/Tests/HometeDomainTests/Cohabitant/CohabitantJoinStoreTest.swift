//
//  CohabitantJoinStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct CohabitantJoinStoreTest {

    @Test("参加に成功した場合、完了状態になりアカウントのグループIDが同期される")
    func join_success() async {
        // Arrange
        let initialAccount = Account(id: "testId", userName: "testUser", fcmToken: nil, cohabitantId: nil)
        let expectedAccount = Account(
            id: "testId",
            userName: "testUser",
            fcmToken: nil,
            cohabitantId: "joinedCohabitantId"
        )
        let accountStore = AccountStore(account: initialAccount)
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(join: { token in
                #expect(token == "test-token")
                return "joinedCohabitantId"
            }),
            accountStore: accountStore
        )

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .completed)
        #expect(accountStore.account == expectedAccount)
    }

    @Test(
        "参加に失敗した場合、エラーに応じた失敗状態になる",
        arguments: [
            (CohabitantInvitationError.notFound, CohabitantJoinFailure.invalidLink),
            (CohabitantInvitationError.expired, CohabitantJoinFailure.expired),
            (CohabitantInvitationError.alreadyJoined, CohabitantJoinFailure.alreadyJoined),
        ]
    )
    func join_failure(error: CohabitantInvitationError, expected: CohabitantJoinFailure) async {
        // Arrange
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(join: { _ in throw error })
        )

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .failed(expected))
    }

    @Test("招待以外のエラーで失敗した場合、原因不明の失敗状態になる")
    func join_unknownError() async {
        // Arrange
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(join: { _ in throw DomainError.noNetwork })
        )

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .failed(.unknown))
    }

    @Test("参加に失敗した場合、アカウントのグループIDは更新されない")
    func join_failure_doesNotUpdateAccount() async {
        // Arrange
        let initialAccount = Account(id: "testId", userName: "testUser", fcmToken: nil, cohabitantId: nil)
        let accountStore = AccountStore(account: initialAccount)
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(join: { _ in throw CohabitantInvitationError.expired }),
            accountStore: accountStore
        )

        // Act
        await sut.join()

        // Assert
        #expect(accountStore.account == initialAccount)
    }

}
