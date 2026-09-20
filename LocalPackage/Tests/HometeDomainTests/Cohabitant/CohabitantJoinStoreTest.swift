//
//  CohabitantJoinStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct CohabitantJoinStoreTest {

    // MARK: - load

    @Test("招待の概要を取得できた場合、招待者名を持った確認状態になる")
    func load_success() async {
        // Arrange
        let expectedSummary = CohabitantInvitationSummary(
            inviterName: "たろう",
            expiresAt: Date(timeIntervalSince1970: 100)
        )
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(fetch: { token in
                #expect(token == "test-token")
                return expectedSummary
            })
        )

        // Act
        await sut.load()

        // Assert
        #expect(sut.state == .confirming(expectedSummary))
    }

    @Test(
        "招待の概要の取得に失敗した場合、参加ボタンを押す前にエラーに応じた失敗状態になる",
        arguments: [
            (CohabitantInvitationError.notFound, CohabitantJoinFailure.invalidLink),
            (CohabitantInvitationError.expired, CohabitantJoinFailure.expired),
        ]
    )
    func load_failure(error: CohabitantInvitationError, expected: CohabitantJoinFailure) async {
        // Arrange
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(fetch: { _ in throw error })
        )

        // Act
        await sut.load()

        // Assert
        #expect(sut.state == .failed(expected))
    }

    @Test("招待以外のエラーで取得に失敗した場合、原因不明の失敗状態になる")
    func load_unknownError() async {
        // Arrange
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(fetch: { _ in throw DomainError.noNetwork })
        )

        // Act
        await sut.load()

        // Assert
        #expect(sut.state == .failed(.unknown))
    }

    @Test("取得済みの場合は再度取得しない")
    func load_onlyOnce() async {
        // Arrange
        let fetchCount = FetchCounter()
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(fetch: { _ in
                await fetchCount.increment()
                return .preview
            })
        )

        // Act
        await sut.load()
        await sut.load()

        // Assert
        #expect(await fetchCount.value == 1)
        #expect(sut.state == .confirming(.preview))
    }

    // MARK: - join

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
                return .init(cohabitantId: "joinedCohabitantId", isNewMember: true)
            }),
            accountStore: accountStore
        )
        await sut.load()

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .completed)
        #expect(accountStore.account == expectedAccount)
    }

    @Test("すでに参加済みのグループだった場合、参加済み状態になりアカウントのグループIDが同期される")
    func join_alreadyMember() async {
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
            cohabitantInvitationClient: .init(join: { _ in
                .init(cohabitantId: "joinedCohabitantId", isNewMember: false)
            }),
            accountStore: accountStore
        )
        await sut.load()

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .alreadyMember)
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
        await sut.load()

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
        await sut.load()

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
        await sut.load()

        // Act
        await sut.join()

        // Assert
        #expect(accountStore.account == initialAccount)
    }

    @Test("招待の概要を取得できていない場合は参加しない")
    func join_beforeLoaded() async {
        // Arrange
        let sut = CohabitantJoinStore(
            token: "test-token",
            cohabitantInvitationClient: .init(join: { _ in
                Issue.record("取得前に参加処理が呼ばれた")
                return .init(cohabitantId: "joinedCohabitantId", isNewMember: true)
            })
        )

        // Act
        await sut.join()

        // Assert
        #expect(sut.state == .loading)
    }

}

private actor FetchCounter {

    private(set) var value = 0

    func increment() {
        value += 1
    }

}
