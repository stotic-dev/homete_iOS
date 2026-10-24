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

    @Test("別の招待トークンを読み込んでいる間は、前の招待の案内を出さない")
    func load_anotherTokenWhileFetching() async {
        // Arrange
        let (fetchStarted, fetchStartedContinuation) = AsyncStream<Void>.makeStream()
        let (fetchResumed, fetchResumedContinuation) = AsyncStream<Void>.makeStream()
        let sut = WelcomeInvitationStore(
            cohabitantInvitationClient: .init(fetch: { token in
                guard token == "token-b" else {
                    return .init(inviterName: "たろう", expiresAt: Date(timeIntervalSince1970: 100))
                }
                fetchStartedContinuation.yield()
                for await _ in fetchResumed {
                    break
                }
                return .init(inviterName: "はなこ", expiresAt: Date(timeIntervalSince1970: 100))
            })
        )
        await sut.load(token: "token-a")

        // Act
        let loading = Task {
            await sut.load(token: "token-b")
        }
        for await _ in fetchStarted {
            break
        }

        // Assert
        #expect(sut.invitation == .none)

        fetchResumedContinuation.yield()
        await loading.value
    }

}
