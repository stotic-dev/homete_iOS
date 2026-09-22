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
                myAccountId: myAccountId,
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
            myAccountId: myAccountId,
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

    @Test("同居人レコードの作成が要求されたら作成し、完了後に同居人IDの共有を送信する")
    func send_effectRegisterCohabitant() async {
        // Arrange
        let expectedCohabitant = CohabitantData(id: cohabitantId, members: [myAccountId, "b-account"])
        let expectedMessage = CohabitantRegistrationMessage(type: .shareCohabitantId(id: cohabitantId))

        let _: Void = await withCheckedContinuation { continuation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                myAccountId: myAccountId,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    continuation.resume()
                },
                cohabitantClient: .init(register: { cohabitant in
                    #expect(cohabitant == expectedCohabitant)
                }),
                makeCohabitantId: { cohabitantId },
                initialState: .init(
                    phase: .processing(.init(role: .lead(.init()))),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.send(.received(.init(type: .preRegistration(role: .follower(accountId: "b-account"))), from: peerB))
        }
    }

    @Test("同居人レコードの作成に失敗したら、失敗イベントとして状態機械へ戻し登録失敗のアラートを出す")
    func send_effectRegisterCohabitant_failed() async {
        // Arrange
        let expectedState = State(
            phase: .processing(
                .init(
                    role: .lead(.init(followerAccountIds: ["b-account"], cohabitantId: cohabitantId)),
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
                myAccountId: myAccountId,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                cohabitantClient: .init(register: { _ in throw ClientError() }),
                analyticsClient: .init(log: { event in
                    // 失敗イベントの送信は状態機械が失敗を処理した後に行われるため、ここで待機を解除する
                    #expect(event == .cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
                    continuation.resume()
                }),
                makeCohabitantId: { cohabitantId },
                initialState: .init(
                    phase: .processing(.init(role: .lead(.init()))),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(
                .received(.init(type: .preRegistration(role: .follower(accountId: "b-account"))), from: peerB)
            )
        }

        // Assert
        #expect(store.value?.state == expectedState)
    }

    @Test("同居人IDの保存が要求されたら自分のアカウントへ保存し、完了後にリーダーへ完了を送信する")
    func send_effectSaveCohabitantId() async {
        // Arrange
        let account = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: nil)
        let expectedAccount = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: cohabitantId)
        let expectedMessage = CohabitantRegistrationMessage(type: .complete)

        let _: Void = await withCheckedContinuation { continuation in
            let store = CohabitantRegistrationStore(
                myPeerID: me,
                myAccountId: myAccountId,
                messageSender: MessageSenderMock { message, peers in
                    // Assert
                    #expect(message == expectedMessage)
                    #expect(peers == [peerB])
                    continuation.resume()
                },
                accountStore: .init(
                    accountInfoClient: .init(insertOrUpdate: { updatedAccount in
                        #expect(updatedAccount == expectedAccount)
                    }),
                    account: account
                ),
                initialState: .init(
                    phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.send(.received(.init(type: .shareCohabitantId(id: cohabitantId)), from: peerB))
        }
    }

    @Test("同居人IDの保存に失敗したら、失敗イベントとして状態機械へ戻し登録失敗のアラートを出す")
    func send_effectSaveCohabitantId_failed() async {
        // Arrange
        let account = Account(id: myAccountId, userName: "me", fcmToken: nil, cohabitantId: nil)
        let expectedState = State(
            phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
            connectedPeers: [peerB],
            alert: .registrationFailed
        )
        let store = TestBox<CohabitantRegistrationStore?>(value: nil)

        let _: Void = await withCheckedContinuation { continuation in
            store.value = CohabitantRegistrationStore(
                myPeerID: me,
                myAccountId: myAccountId,
                messageSender: MessageSenderMock { _, _ in Issue.record() },
                analyticsClient: .init(log: { event in
                    #expect(event == .cohabitantRegistration(.completed(method: .p2p, isSuccess: false)))
                    continuation.resume()
                }),
                accountStore: .init(
                    accountInfoClient: .init(insertOrUpdate: { _ in throw ClientError() }),
                    account: account
                ),
                initialState: .init(
                    phase: .processing(.init(role: .follower(.init(leadPeer: peerB)), confirmedRolePeers: [peerB])),
                    connectedPeers: [peerB]
                )
            )

            // Act
            store.value?.send(.received(.init(type: .shareCohabitantId(id: cohabitantId)), from: peerB))
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
                myAccountId: myAccountId,
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
