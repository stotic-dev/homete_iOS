//
//  CohabitantRegistrationStateMachineTests.swift
//  LocalPackage
//

// swiftlint:disable file_length

@testable import HometeDomain
import Testing

enum CohabitantRegistrationStateMachineTests {

    typealias PeerID = CohabitantRegistrationPeerID
    typealias State = CohabitantRegistrationState
    typealias Effect = CohabitantRegistrationEffect

    /// displayNameの辞書順で最小なので、全員が宣言したときリーダーになる
    static let me = PeerID(displayName: "A_me")
    static let peerB = PeerID(displayName: "B_peer")
    static let peerC = PeerID(displayName: "C_peer")
    static let myAccountId = "my-account"
    static let cohabitantId = "cohabitant-id"

    static func makeSUT(myPeerID: PeerID = me) -> CohabitantRegistrationStateMachine {
        .init(myPeerID: myPeerID, myAccountId: myAccountId, makeCohabitantId: { cohabitantId })
    }

    struct ScanningCase {}
    struct ProcessingCommonCase {}
    struct LeadCase {}
    struct FollowerCase {}

}

// MARK: - メンバーを探している状態

extension CohabitantRegistrationStateMachineTests.ScanningCase {

    typealias Tests = CohabitantRegistrationStateMachineTests

    @Test("メンバーが初めて見つかったら、接続中メンバーを更新して発見イベントを送る")
    func peersChanged_firstPeerFound() {
        // Arrange
        var state = Tests.State()
        let expectedState = Tests.State(connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .peersChanged([Tests.peerB]))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.log(.peerFound)])
    }

    @Test("すでにメンバーがいる状態で増減しても、発見イベントは送らない")
    func peersChanged_additionalPeer() {
        // Arrange
        var state = Tests.State(connectedPeers: [Tests.peerB])
        let expectedState = Tests.State(connectedPeers: [Tests.peerB, Tests.peerC])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .peersChanged([Tests.peerB, Tests.peerC]))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("接続が全て切れたら、自分と相手の宣言をどちらも忘れる")
    func peersChanged_allDisconnected() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true, confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State()

        // Act
        let effects = Tests.makeSUT().reduce(&state, .peersChanged([]))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("登録開始を宣言したら、宣言済みにして相手へ通知する")
    func userConfirmedMembers_ok() {
        // Arrange
        var state = Tests.State(connectedPeers: [Tests.peerB])
        let expectedState = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userConfirmedMembers(isOK: true))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .fixedMember(isOK: true)), to: [Tests.peerB])])
    }

    @Test("登録開始をキャンセルしたら、受け取っていた相手の宣言を忘れてキャンセルを通知する")
    func userConfirmedMembers_cancel() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userConfirmedMembers(isOK: false))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .fixedMember(isOK: false)), to: [Tests.peerB])])
    }

    @Test("相手の宣言が先に届いている状態で自分も宣言したら、名前順が最小の自分がリーダーとして登録処理へ進む")
    func userConfirmedMembers_allConfirmed_becomesLead() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userConfirmedMembers(isOK: true))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .fixedMember(isOK: true)), to: [Tests.peerB])])
    }

    @Test("相手の宣言が先に届いている状態で自分も宣言したら、名前順が最小でない自分はフォロワーとして登録処理へ進む")
    func userConfirmedMembers_allConfirmed_becomesFollower() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT(myPeerID: Tests.peerC).reduce(&state, .userConfirmedMembers(isOK: true))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .fixedMember(isOK: true)), to: [Tests.peerB])])
    }

    @Test("自分が宣言済みの状態で相手の宣言が届いたら、登録処理へ進む")
    func receivedFixedMember_afterMyConfirmation() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .fixedMember(isOK: true)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("自分が未宣言の状態で相手の宣言が届いても、宣言を覚えるだけで登録処理には進まない")
    func receivedFixedMember_beforeMyConfirmation() {
        // Arrange
        var state = Tests.State(connectedPeers: [Tests.peerB])
        let expectedState = Tests.State(
            phase: .scanning(.init(confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .fixedMember(isOK: true)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("3台中1台の宣言しか届いていなければ、自分が宣言済みでも登録処理には進まない")
    func receivedFixedMember_notAllPeersConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = Tests.State(
            phase: .scanning(.init(isConfirmed: true, confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .fixedMember(isOK: true)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("相手のキャンセルが届いたら、相手の宣言を忘れてキャンセルのアラートを出す")
    func receivedFixedMember_rejected() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true, confirmedPeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB],
            alert: .rejectedByPeer
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .fixedMember(isOK: false)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("キャンセルのアラートを閉じたら、自分の宣言もやり直しにする")
    func userDismissedAlert_rejectedByPeer() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB],
            alert: .rejectedByPeer
        )
        let expectedState = Tests.State(connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userDismissedAlert)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("宣言の送信に失敗したら、送信失敗のアラートを出す")
    func sendFailed() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB],
            alert: .sendFailed
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .sendFailed)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("送信失敗のアラートを閉じても、宣言の状態は変えない")
    func userDismissedAlert_sendFailed() {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB],
            alert: .sendFailed
        )
        let expectedState = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userDismissedAlert)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test(
        "メンバー確定以外のメッセージは無視する",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.preRegistration(role: .lead),
            .shareCohabitantId(id: "id"),
            .complete
        ]
    )
    func received_otherMessages(type: CohabitantRegistrationMessage.CommunicateType) {
        // Arrange
        var state = Tests.State(
            phase: .scanning(.init(isConfirmed: true)),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .received(.init(type: type), from: Tests.peerB))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("登録処理中の定期送信のタイミングは無視する")
    func tick_ignored() {
        // Arrange
        var state = Tests.State(connectedPeers: [Tests.peerB])
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .tick)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

}

// MARK: - 登録処理中（役割共通）

extension CohabitantRegistrationStateMachineTests.ProcessingCommonCase {

    typealias Tests = CohabitantRegistrationStateMachineTests

    @Test("役割が揃っていなければ、定期送信のタイミングでリーダーの役割を全員へ送る")
    func tick_lead_notAllConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .tick)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .preRegistration(role: .lead)), to: [Tests.peerB])])
    }

    @Test("役割が揃っていなければ、定期送信のタイミングで自分のアカウントIDを添えたフォロワーの役割を全員へ送る")
    func tick_follower_notAllConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .tick)

        // Assert
        #expect(state == expectedState)
        #expect(
            effects == [
                .send(.init(type: .preRegistration(role: .follower(accountId: Tests.myAccountId))), to: [Tests.peerB]),
            ]
        )
    }

    @Test("全員の役割が揃っていれば、定期送信のタイミングでも何も送らない")
    func tick_allConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .tick)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("登録処理中に接続中メンバーが変わったら、接続エラーのアラートを出す")
    func peersChanged_showsConnectionError() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [],
            alert: .connectionError
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .peersChanged([]))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("接続エラーのアラートを閉じたら、メンバーの選び直しに戻る")
    func userDismissedAlert_connectionError() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB],
            alert: .connectionError
        )
        let expectedState = Tests.State(connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userDismissedAlert)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("登録処理中の送信失敗は、切断に伴う接続エラーで拾うため無視する")
    func sendFailed_ignored() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .sendFailed)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("同居人IDの保存に失敗したら、登録失敗のアラートを出して失敗イベントを送る")
    func cohabitantIdSaveFailed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB],
            alert: .registrationFailed
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantIdSaveFailed)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.log(.completed(method: .p2p, isSuccess: false))])
    }

    @Test("登録失敗のアラートを閉じたら、画面を閉じる要求を立てる")
    func userDismissedAlert_registrationFailed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB],
            alert: .registrationFailed
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB],
            isDismissRequested: true
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .userDismissedAlert)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

}

// MARK: - リーダー

extension CohabitantRegistrationStateMachineTests.LeadCase {

    typealias Tests = CohabitantRegistrationStateMachineTests

    @Test("全フォロワーの役割が揃ったら、同居人IDを採番して自分と全フォロワーのアカウントIDで同居人レコードを作成する")
    func receivedFollowerRole_allConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(role: .lead(.init(followerAccountIds: ["b-account"])), confirmedRolePeers: [Tests.peerB])
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(
                        .init(followerAccountIds: ["b-account", "c-account"], cohabitantId: Tests.cohabitantId)
                    ),
                    confirmedRolePeers: [Tests.peerB, Tests.peerC]
                )
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .follower(accountId: "c-account"))), from: Tests.peerC)
        )

        // Assert
        #expect(state == expectedState)
        #expect(
            effects == [
                .registerCohabitant(
                    .init(id: Tests.cohabitantId, members: [Tests.myAccountId, "b-account", "c-account"])
                ),
            ]
        )
    }

    @Test("フォロワーの役割が一部しか届いていなければ、アカウントIDを覚えるだけでレコードは作成しない")
    func receivedFollowerRole_notAllConfirmed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(role: .lead(.init(followerAccountIds: ["b-account"])), confirmedRolePeers: [Tests.peerB])
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .follower(accountId: "b-account"))), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("同じフォロワーの役割が再度届いても、レコードを二重に作成しない")
    func receivedFollowerRole_duplicated() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(followerAccountIds: ["b-account"], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .follower(accountId: "b-account"))), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("相手もリーダーを名乗っていたら、接続エラーとしてメンバーの選び直しに倒す")
    func receivedLeadRole_conflicted() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .lead(.init()))),
            connectedPeers: [Tests.peerB],
            alert: .connectionError
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .lead)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("同居人レコードの作成が完了したら、同居人IDを全員へ共有する")
    func cohabitantRegistered() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(role: .lead(.init(cohabitantId: Tests.cohabitantId)), confirmedRolePeers: [Tests.peerB])
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantRegistered)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .shareCohabitantId(id: Tests.cohabitantId)), to: [Tests.peerB])])
    }

    @Test("同居人レコードの作成に失敗したら、登録失敗のアラートを出して失敗イベントを送る")
    func cohabitantRegistrationFailed() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(role: .lead(.init(cohabitantId: Tests.cohabitantId)), confirmedRolePeers: [Tests.peerB])
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(role: .lead(.init(cohabitantId: Tests.cohabitantId)), confirmedRolePeers: [Tests.peerB])
            ),
            connectedPeers: [Tests.peerB],
            alert: .registrationFailed
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantRegistrationFailed)

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.log(.completed(method: .p2p, isSuccess: false))])
    }

    @Test("全フォロワーの完了通知が届いたら、自分のアカウントに同居人IDを保存する")
    func receivedComplete_allCompleted() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [Tests.peerB], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB, Tests.peerC]
                )
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [Tests.peerB, Tests.peerC], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB, Tests.peerC]
                )
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .received(.init(type: .complete), from: Tests.peerC))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.saveCohabitantId(Tests.cohabitantId)])
    }

    @Test("完了通知が一部しか届いていなければ、完了したメンバーを覚えるだけで保存はしない")
    func receivedComplete_notAllCompleted() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB, Tests.peerC]
                )
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [Tests.peerB], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB, Tests.peerC]
                )
            ),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .received(.init(type: .complete), from: Tests.peerB))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("同じフォロワーから完了通知が再度届いても、二重に保存しない")
    func receivedComplete_duplicated() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [Tests.peerB], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(&state, .received(.init(type: .complete), from: Tests.peerB))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("自分のアカウントへの保存が済んだら、完了イベントを送ってから全員へ完了を通知し、登録完了にする")
    func cohabitantIdSaved() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .lead(.init(completedPeers: [Tests.peerB], cohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(phase: .completed, connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantIdSaved(Tests.cohabitantId))

        // Assert
        #expect(state == expectedState)
        #expect(
            effects == [
                .log(.completed(method: .p2p, isSuccess: true)),
                .send(.init(type: .complete), to: [Tests.peerB]),
            ]
        )
    }

}

// MARK: - フォロワー

extension CohabitantRegistrationStateMachineTests.FollowerCase {

    typealias Tests = CohabitantRegistrationStateMachineTests

    @Test("リーダーの役割が届いたら、送信元をリーダーとして覚える")
    func receivedLeadRole() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .lead)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("他のフォロワーの役割が届いても無視する")
    func receivedFollowerRole_ignored() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB, Tests.peerC]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .follower(accountId: "c-account"))), from: Tests.peerC)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

    @Test("同居人IDが届いたら、自分のアカウントに保存する")
    func receivedCohabitantId() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = state

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .shareCohabitantId(id: Tests.cohabitantId)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.saveCohabitantId(Tests.cohabitantId)])
    }

    @Test("リーダーの役割が届く前に同居人IDが届いたら、送信元をリーダーとして扱った上で保存する")
    func receivedCohabitantId_beforeLeadRole() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .shareCohabitantId(id: Tests.cohabitantId)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.saveCohabitantId(Tests.cohabitantId)])
    }

    @Test("自分のアカウントへの保存が済んだら、完了イベントを送ってからリーダーへ完了を通知する")
    func cohabitantIdSaved_leadKnown() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init(leadPeer: Tests.peerB)), confirmedRolePeers: [Tests.peerB])),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(
                    role: .follower(.init(leadPeer: Tests.peerB, registeredCohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantIdSaved(Tests.cohabitantId))

        // Assert
        #expect(state == expectedState)
        #expect(
            effects == [
                .log(.completed(method: .p2p, isSuccess: true)),
                .send(.init(type: .complete), to: [Tests.peerB]),
            ]
        )
    }

    @Test("リーダーが分からないまま保存が済んだら、完了イベントだけ送って完了の通知は保留する")
    func cohabitantIdSaved_leadUnknown() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init()))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(.init(role: .follower(.init(registeredCohabitantId: Tests.cohabitantId)))),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(&state, .cohabitantIdSaved(Tests.cohabitantId))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.log(.completed(method: .p2p, isSuccess: true))])
    }

    @Test("保存済みの状態でリーダーの役割が届いたら、保留していた完了をリーダーへ通知する")
    func receivedLeadRole_afterSaved() {
        // Arrange
        var state = Tests.State(
            phase: .processing(.init(role: .follower(.init(registeredCohabitantId: Tests.cohabitantId)))),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(
            phase: .processing(
                .init(
                    role: .follower(.init(leadPeer: Tests.peerB, registeredCohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )

        // Act
        let effects = Tests.makeSUT().reduce(
            &state,
            .received(.init(type: .preRegistration(role: .lead)), from: Tests.peerB)
        )

        // Assert
        #expect(state == expectedState)
        #expect(effects == [.send(.init(type: .complete), to: [Tests.peerB])])
    }

    @Test("リーダーから完了通知が届いたら、登録完了にする")
    func receivedComplete() {
        // Arrange
        var state = Tests.State(
            phase: .processing(
                .init(
                    role: .follower(.init(leadPeer: Tests.peerB, registeredCohabitantId: Tests.cohabitantId)),
                    confirmedRolePeers: [Tests.peerB]
                )
            ),
            connectedPeers: [Tests.peerB]
        )
        let expectedState = Tests.State(phase: .completed, connectedPeers: [Tests.peerB])

        // Act
        let effects = Tests.makeSUT().reduce(&state, .received(.init(type: .complete), from: Tests.peerB))

        // Assert
        #expect(state == expectedState)
        #expect(effects == [])
    }

}
