//
//  AppIntentSessionUseCaseTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct AppIntentSessionUseCaseTest {

    private let account = Account(id: "own", userName: "たろう", cohabitantId: "cohabitant")

    @Test("ログイン中でグループに所属していれば、アカウントとグループを返す")
    func resolve() async throws {
        // Arrange

        let sut = makeSUT(authId: "own", account: account)
        let expected = AppIntentSession(account: account, cohabitantId: "cohabitant")

        // Act

        let actual = try await sut.resolve(requiresLatestVersion: true)

        // Assert

        #expect(actual == expected)
    }

    @Test("ログインしていない場合は、notLoggedInを投げる")
    func resolveWithoutLogin() async {
        // Arrange

        let sut = makeSUT(authId: nil, account: account)

        // Act & Assert

        await #expect(throws: AppIntentFailure.notLoggedIn) {
            try await sut.resolve(requiresLatestVersion: false)
        }
    }

    @Test("アカウントの登録を終えていない場合は、notLoggedInを投げる")
    func resolveWithoutAccount() async {
        // Arrange

        let sut = makeSUT(authId: "own", account: nil)

        // Act & Assert

        await #expect(throws: AppIntentFailure.notLoggedIn) {
            try await sut.resolve(requiresLatestVersion: false)
        }
    }

    @Test("グループに所属していない場合は、noCohabitantを投げる")
    func resolveWithoutCohabitant() async {
        // Arrange

        let sut = makeSUT(
            authId: "own",
            account: .init(id: "own", userName: "たろう", cohabitantId: nil)
        )

        // Act & Assert

        await #expect(throws: AppIntentFailure.noCohabitant) {
            try await sut.resolve(requiresLatestVersion: false)
        }
    }

    @Test("書き込むIntentで強制アップデートが必要なバージョンの場合は、updateRequiredを投げる")
    func resolveRequiringUpdate() async {
        // Arrange

        let sut = makeSUT(authId: "own", account: account, minimumRequiredVersion: "2.0.0")

        // Act & Assert

        await #expect(throws: AppIntentFailure.updateRequired) {
            try await sut.resolve(requiresLatestVersion: true)
        }
    }

    @Test("読むだけのIntentでは、強制アップデートが必要なバージョンでも実行できる")
    func resolveReadOnlyRequiringUpdate() async throws {
        // Arrange

        let sut = makeSUT(authId: "own", account: account, minimumRequiredVersion: "2.0.0")
        let expected = AppIntentSession(account: account, cohabitantId: "cohabitant")

        // Act

        let actual = try await sut.resolve(requiresLatestVersion: false)

        // Assert

        #expect(actual == expected)
    }

    @Test("グループのメンバーを、自分と読み込めたメンバーの名前で返す")
    func fetchMembers() async throws {
        // Arrange

        let accounts = [
            "partner": Account(id: "partner", userName: "はなこ", cohabitantId: "cohabitant"),
        ]
        let sut = AppIntentSessionUseCase(
            accountAuthClient: .init(),
            accountInfoClient: .init(fetch: { accounts[$0] }),
            cohabitantClient: .init(addSnapshotListener: { _, _ in
                AsyncThrowingStream {
                    $0.yield(CohabitantData(id: "cohabitant", members: ["own", "partner", "left"]))
                }
            }),
            houseworkClient: .init(),
            houseworkTemplateClient: .init(),
            remoteConfigClient: .init(),
            currentAppVersion: "1.0.0"
        )
        let expected = CohabitantMemberList(
            value: [.init(id: "own", userName: "たろう"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        )

        // Act

        let actual = try await sut.fetchMembers(session: .init(account: account, cohabitantId: "cohabitant"))

        // Assert

        #expect(actual == expected)
    }

}

private extension AppIntentSessionUseCaseTest {

    func makeSUT(
        authId: String?,
        account: Account?,
        minimumRequiredVersion: String = ""
    ) -> AppIntentSessionUseCase {
        .init(
            accountAuthClient: .init(currentAuth: { authId.map { AccountAuthResult(id: $0) } }),
            accountInfoClient: .init(fetch: { _ in account }),
            cohabitantClient: .init(),
            houseworkClient: .init(),
            houseworkTemplateClient: .init(),
            remoteConfigClient: .init(string: { _ in minimumRequiredVersion }),
            currentAppVersion: "1.0.0"
        )
    }

}
