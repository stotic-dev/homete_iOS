//
//  SentInvitationStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct SentInvitationStoreTest {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    @Test("送った招待を、送ったアカウントと一緒に端末へ保存する")
    func save() async {
        await confirmation { saved in
            // Arrange

            let expected = SentCohabitantInvitation(
                accountId: "accountId",
                token: "token",
                expiresAt: now.addingTimeInterval(60)
            )
            let sut = SentInvitationStore(sentInvitationClient: .init(save: { invitation in
                #expect(invitation == expected)
                saved()
            }))

            // Act

            await sut.save(
                CohabitantInvitation(
                    token: "token",
                    cohabitantId: "cohabitantId",
                    expiresAt: now.addingTimeInterval(60)
                ),
                accountId: "accountId"
            )

            // Assert

            #expect(sut.sentInvitation == expected)
        }
    }

    @Test("端末に保存した招待を読み出す")
    func loadIfNeeded() async {
        // Arrange

        let stored = SentCohabitantInvitation(accountId: "accountId", token: "token", expiresAt: now)
        let sut = SentInvitationStore(sentInvitationClient: .init(load: { stored }))

        // Act

        await sut.loadIfNeeded()

        // Assert

        #expect(sut.sentInvitation == stored)
    }

    @Test("端末からの読み出しは最初の1回だけ行う")
    func loadIfNeeded_onlyOnce() async {
        await confirmation(expectedCount: 1) { loaded in
            // Arrange

            let sut = SentInvitationStore(sentInvitationClient: .init(load: {
                loaded()
                return nil
            }))
            await sut.loadIfNeeded()

            // Act

            await sut.loadIfNeeded()
        }
    }

    @Test("記録した招待を、端末からも消す")
    func clear() async {
        await confirmation { cleared in
            // Arrange

            let sut = SentInvitationStore(sentInvitationClient: .init(clear: { cleared() }))
            await sut.save(
                CohabitantInvitation(token: "token", cohabitantId: nil, expiresAt: now),
                accountId: "accountId"
            )

            // Act

            await sut.clear()

            // Assert

            #expect(sut.sentInvitation == nil)
        }
    }

    @Test("自分が送った有効期限内の招待は、参加を待っている招待として返す")
    func waitingInvitation() async {
        // Arrange

        let sut = SentInvitationStore()
        await sut.save(
            CohabitantInvitation(token: "token", cohabitantId: "cohabitantId", expiresAt: now.addingTimeInterval(1)),
            accountId: "accountId"
        )

        // Act

        let actual = sut.waitingInvitation(accountId: "accountId", now: now)

        // Assert

        #expect(actual == CohabitantInvitation(token: "token", cohabitantId: nil, expiresAt: now.addingTimeInterval(1)))
    }

    @Test("有効期限を過ぎた招待は、参加を待っている招待として返さない")
    func waitingInvitation_expired() async {
        // Arrange

        let sut = SentInvitationStore()
        await sut.save(
            CohabitantInvitation(token: "token", cohabitantId: nil, expiresAt: now),
            accountId: "accountId"
        )

        // Act

        let actual = sut.waitingInvitation(accountId: "accountId", now: now)

        // Assert

        #expect(actual == nil)
    }

    @Test("別のアカウントが送った招待は、参加を待っている招待として返さない")
    func waitingInvitation_otherAccount() async {
        // Arrange

        let sut = SentInvitationStore()
        await sut.save(
            CohabitantInvitation(token: "token", cohabitantId: nil, expiresAt: now.addingTimeInterval(1)),
            accountId: "deletedAnonymousAccountId"
        )

        // Act

        let actual = sut.waitingInvitation(accountId: "accountId", now: now)

        // Assert

        #expect(actual == nil)
    }

}
