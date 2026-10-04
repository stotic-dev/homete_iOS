//
//  CohabitantRegistrationStoreTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

@MainActor
struct CohabitantRegistrationStoreTest {

    typealias PeerID = CohabitantRegistrationPeerID
    typealias State = CohabitantRegistrationState

    private let me = PeerID(displayName: "A_me")
    private let peerB = PeerID(displayName: "B_peer")
    private let myAccountId = "my-account"
    private let cohabitantId = "cohabitant-id"
    private let invitationToken = "invitation-token"

    private struct SendError: Error {}
    private struct ClientError: Error {}

    @Test("送信の要求があったら、メッセージと宛先をそのまま送信する")
    func send_effectSend() async {
        // Arrange
        let expectedMessage = CohabitantRegistrationMessage(type: .fixedMember(isOK: true))
        let expectedState = State(phase: .scanning(.init(isConfirmed: true)), connectedPeers: [peerB])

        await confirmation(expectedCount: 1) { confirmation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    confirmation()
                },
                initialState: .init(connectedPeers: [peerB])
            )

            // Act
            store.send(.userConfirmedMembers(isOK: true))

            #expect(store.state == expectedState)
        }
    }

    @Test("送信に失敗したら、送信失敗のイベントとして状態機械へ戻す")
    func send_effectSend_failed() {
        // Arrange
        let store = CohabitantRegistrationStore(
            myPeerID: me,
            messageSender: MessageSenderMock { _, _ in throw SendError() },
            initialState: .init(connectedPeers: [peerB])
        )
        let expectedState = State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [peerB],
            alert: .sendFailed
        )

        // Act
        store.send(.userConfirmedMembers(isOK: true))

        // Assert
        #expect(store.state == expectedState)
    }

    @Test("招待トークンの発行が要求されたら発行し、完了後に招待トークンの共有を送信する")
    func send_effectIssueInvitation() async {
        // Arrange
        let expectedMessage = CohabitantRegistrationMessage(type: .shareInvitation(token: invitationToken))

        let _: Void = await withCheckedContinuation { continuation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    continuation.resume()
                },
                cohabitantInvitationClient: .init(issue: {
                    .init(token: invitationToken, cohabitantId: nil, expiresAt: .distantFuture)
                }),
                initialState: .init(
                    phase: .processing(.init(role: .lead(.init()))),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.send(.received(.init(type: .preRegistration(role: .follower)), from: peerB))
        }
    }

    @Test("招待トークンの発行に失敗したら、失敗イベントとして状態機械へ戻し登録失敗のアラートを出す")
    func send_effectIssueInvitation_failed() async {
        // Arrange
        let expectedState = State(
            phase: .processing(.init(role: .lead(.init()), confirmedRolePeers: [peerB])),
            connectedPeers: [peerB],
            alert: .registrationFailed
        )
        let store = TestBox<CohabitantRegistrationStore?>(value: nil)

        let _: Void = await withCheckedContinuation { continuation in
            store.value = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                cohabitantInvitationClient: .init(issue: { throw ClientError() }),
                analyticsClient: .init(log: { event in
                    // 失敗イベントの送信は状態機械が失敗を処理した後に行われるため、ここで待機を解除する
                    #expect(event == .cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
                    continuation.resume()
                }),
                initialState: .init(
                    phase: .processing(.init(role: .lead(.init()))),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(.received(.init(type: .preRegistration(role: .follower)), from: peerB))
        }

        // Assert
        #expect(store.value?.state == expectedState)
    }

    @Test("グループへの参加が要求されたら招待トークンで参加し、参加先を自分のアカウントに反映してからリーダーへ完了を送信する")
    func send_effectJoinCohabitant() async {
        // Arrange
        let account = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: nil)
        let expectedAccount = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: cohabitantId)
        let expectedMessage = CohabitantRegistrationMessage(type: .complete)
        let accountStore = AccountStore(account: account)

        let _: Void = await withCheckedContinuation { continuation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    continuation.resume()
                },
                cohabitantInvitationClient: .init(join: { token in
                    #expect(token == invitationToken)
                    return .init(cohabitantId: cohabitantId, isNewMember: true)
                }),
                accountStore: accountStore,
                initialState: .init(
                    phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.send(.received(.init(type: .shareInvitation(token: invitationToken)), from: peerB))
        }

        // Assert
        #expect(accountStore.account == expectedAccount)
    }

    @Test("グループへの参加に失敗したら、失敗イベントとして状態機械へ戻し登録失敗のアラートを出す")
    func send_effectJoinCohabitant_failed() async {
        // Arrange
        let expectedState = State(
            phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
            connectedPeers: [peerB],
            alert: .registrationFailed
        )
        let store = TestBox<CohabitantRegistrationStore?>(value: nil)

        let _: Void = await withCheckedContinuation { continuation in
            store.value = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                cohabitantInvitationClient: .init(join: { _ in throw ClientError() }),
                analyticsClient: .init(log: { event in
                    #expect(event == .cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
                    continuation.resume()
                }),
                initialState: .init(
                    phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(.received(.init(type: .shareInvitation(token: invitationToken)), from: peerB))
        }

        // Assert
        #expect(store.value?.state == expectedState)
    }

    @Test("アカウントの取り直しが要求されたら取り直し、グループIDが入っていれば全員へ完了を送信して登録完了にする")
    func send_effectReloadAccount() async {
        // Arrange
        let account = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: nil)
        let joinedAccount = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: cohabitantId)
        let expectedMessage = CohabitantRegistrationMessage(type: .complete)
        let expectedState = State(phase: .completed, connectedPeers: [peerB])
        let accountStore = AccountStore(
            accountInfoClient: .init(fetch: { _ in joinedAccount }),
            account: account
        )
        let store = TestBox<CohabitantRegistrationStore?>(value: nil)

        let _: Void = await withCheckedContinuation { continuation in
            store.value = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    continuation.resume()
                },
                accountStore: accountStore,
                initialState: .init(
                    phase: .processing(
                        .init(role: .lead(.init(invitationToken: invitationToken)), confirmedRolePeers: [peerB])
                    ),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(.received(.init(type: .complete), from: peerB))
        }

        // Assert
        #expect(store.value?.state == expectedState)
        #expect(accountStore.account == joinedAccount)
    }

    @Test("取り直したアカウントにグループIDが入っていなければ、失敗イベントとして状態機械へ戻し登録失敗のアラートを出す")
    func send_effectReloadAccount_notJoined() async {
        // Arrange
        let account = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: nil)
        let expectedState = State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [peerB], invitationToken: invitationToken)),
                    confirmedRolePeers: [peerB]
                )
            ),
            connectedPeers: [peerB],
            alert: .registrationFailed
        )
        let store = TestBox<CohabitantRegistrationStore?>(value: nil)

        let _: Void = await withCheckedContinuation { continuation in
            store.value = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                analyticsClient: .init(log: { event in
                    #expect(event == .cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
                    continuation.resume()
                }),
                accountStore: .init(accountInfoClient: .init(fetch: { _ in account }), account: account),
                initialState: .init(
                    phase: .processing(
                        .init(role: .lead(.init(invitationToken: invitationToken)), confirmedRolePeers: [peerB])
                    ),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(.received(.init(type: .complete), from: peerB))
        }

        // Assert
        #expect(store.value?.state == expectedState)
    }

    @Test("Analyticsイベントの送信が要求されたら、同居人登録イベントとして送る")
    func send_effectLog() async {
        // Arrange
        await confirmation(expectedCount: 1) { confirmation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                analyticsClient: .init(log: { event in
                    // Assert
                    #expect(event == .cohabitantRegistration(.peerFound))
                    confirmation()
                })
            )

            // Act
            store.send(.peersChanged([peerB]))
        }
    }

}

private extension CohabitantRegistrationStoreTest {

    final class MessageSenderMock: CohabitantRegistrationMessageSender {

        private let handler: (CohabitantRegistrationMessage, Set<PeerID>) throws -> Void

        init(handler: @escaping (CohabitantRegistrationMessage, Set<PeerID>) throws -> Void) {
            self.handler = handler
        }

        func send(_ message: CohabitantRegistrationMessage, to peers: Set<PeerID>) throws {
            try handler(message, peers)
        }

    }

}
