//
//  CohabitantRegistrationSimulationTests.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

/// 複数端末の状態機械をインメモリで配線し、登録プロトコル全体が全端末で完了に収束することを検証する
struct CohabitantRegistrationSimulationTests {

    typealias PeerID = CohabitantRegistrationPeerID
    typealias State = CohabitantRegistrationState

    static let peerA = PeerID(displayName: "A_peer")
    static let peerB = PeerID(displayName: "B_peer")
    static let peerC = PeerID(displayName: "C_peer")
    static let invitationToken = "invitation-token"

    @Test("2台とも宣言したら、名前順が最小の端末が招待トークンを発行し、相手がそのトークンで参加して両端末とも完了する")
    func twoDevices_leadConfirmsFirst() {
        // Arrange
        var simulation = Simulation(peers: [Self.peerA, Self.peerB])
        let operations: [(PeerID, CohabitantRegistrationEvent)] = [
            (Self.peerA, .userConfirmedMembers(isOK: true)),
            (Self.peerB, .userConfirmedMembers(isOK: true)),
        ]
        let expectedStates: [PeerID: State] = [
            Self.peerA: .init(phase: .completed, connectedPeers: [Self.peerB]),
            Self.peerB: .init(phase: .completed, connectedPeers: [Self.peerA]),
        ]
        let expectedServer = Server(
            invitationIssuers: [Self.peerA],
            joinedPeers: [Self.peerB],
            reloadedPeers: [Self.peerA]
        )

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.server == expectedServer)
    }

    @Test("フォロワー側が先に宣言しても、同じ結果で完了する")
    func twoDevices_followerConfirmsFirst() {
        // Arrange
        var simulation = Simulation(peers: [Self.peerA, Self.peerB])
        let operations: [(PeerID, CohabitantRegistrationEvent)] = [
            (Self.peerB, .userConfirmedMembers(isOK: true)),
            (Self.peerA, .userConfirmedMembers(isOK: true)),
        ]
        let expectedStates: [PeerID: State] = [
            Self.peerA: .init(phase: .completed, connectedPeers: [Self.peerB]),
            Self.peerB: .init(phase: .completed, connectedPeers: [Self.peerA]),
        ]
        let expectedServer = Server(
            invitationIssuers: [Self.peerA],
            joinedPeers: [Self.peerB],
            reloadedPeers: [Self.peerA]
        )

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.server == expectedServer)
    }

    @Test("3台でも、リーダー1台が発行した招待トークンでフォロワー全員が参加して全端末が完了する")
    func threeDevices() {
        // Arrange
        var simulation = Simulation(peers: [Self.peerA, Self.peerB, Self.peerC])
        let operations: [(PeerID, CohabitantRegistrationEvent)] = [
            (Self.peerC, .userConfirmedMembers(isOK: true)),
            (Self.peerA, .userConfirmedMembers(isOK: true)),
            (Self.peerB, .userConfirmedMembers(isOK: true)),
        ]
        let expectedStates: [PeerID: State] = [
            Self.peerA: .init(phase: .completed, connectedPeers: [Self.peerB, Self.peerC]),
            Self.peerB: .init(phase: .completed, connectedPeers: [Self.peerA, Self.peerC]),
            Self.peerC: .init(phase: .completed, connectedPeers: [Self.peerA, Self.peerB]),
        ]
        let expectedServer = Server(
            invitationIssuers: [Self.peerA],
            joinedPeers: [Self.peerB, Self.peerC],
            reloadedPeers: [Self.peerA]
        )

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.server == expectedServer)
    }

    @Test("リーダーの役割通知だけが先に届いても、フォロワーは自分の役割を送り直して完了する")
    func twoDevices_leadRoleArrivesFirst() {
        // Arrange
        var simulation = Simulation(peers: [Self.peerA, Self.peerB])
        let operations: [(PeerID, CohabitantRegistrationEvent)] = [
            (Self.peerB, .userConfirmedMembers(isOK: true)),
            (Self.peerA, .userConfirmedMembers(isOK: true)),
            // 役割の通知が同時ではなくリーダー側だけ先に届くと、フォロワーは相手の役割を知った状態で
            // 最初の定期送信を迎える。ここで自分の役割を送るのをやめると、両者が待ち合って進まなくなる
            (Self.peerA, .tick),
        ]
        let expectedStates: [PeerID: State] = [
            Self.peerA: .init(phase: .completed, connectedPeers: [Self.peerB]),
            Self.peerB: .init(phase: .completed, connectedPeers: [Self.peerA]),
        ]
        let expectedServer = Server(
            invitationIssuers: [Self.peerA],
            joinedPeers: [Self.peerB],
            reloadedPeers: [Self.peerA]
        )

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.server == expectedServer)
    }

    @Test("片方がキャンセルすると相手はアラートを閉じて宣言をやり直し、両者が再度宣言すれば完了する")
    func twoDevices_cancelThenRetry() {
        // Arrange
        var simulation = Simulation(peers: [Self.peerA, Self.peerB])
        let operations: [(PeerID, CohabitantRegistrationEvent)] = [
            (Self.peerB, .userConfirmedMembers(isOK: true)),
            (Self.peerA, .userConfirmedMembers(isOK: false)),
            (Self.peerB, .userDismissedAlert),
            (Self.peerB, .userConfirmedMembers(isOK: true)),
            (Self.peerA, .userConfirmedMembers(isOK: true)),
        ]
        let expectedStates: [PeerID: State] = [
            Self.peerA: .init(phase: .completed, connectedPeers: [Self.peerB]),
            Self.peerB: .init(phase: .completed, connectedPeers: [Self.peerA]),
        ]
        let expectedServer = Server(
            invitationIssuers: [Self.peerA],
            joinedPeers: [Self.peerB],
            reloadedPeers: [Self.peerA]
        )

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.server == expectedServer)
    }

}

// MARK: - シミュレーション

extension CohabitantRegistrationSimulationTests {

    /// サーバー（Cloud Functions）に届いた操作の記録
    struct Server: Equatable {

        /// 招待トークンを発行した端末
        var invitationIssuers: [PeerID] = []
        /// 招待トークンでグループに参加した端末
        var joinedPeers: Set<PeerID> = []
        /// 自分のアカウントを取り直した端末
        var reloadedPeers: [PeerID] = []

    }

    /// 各端末の状態機械と、端末間の送受信・非同期処理の結果を配線するインメモリのハーネス
    /// - Note: 送信は相手端末の受信イベントに、招待の発行・参加・アカウントの取り直しは即時成功の結果イベントに置き換える。
    ///         イベントは1本のキューでFIFOに処理し、キューが空いたら各端末へ役割再送のタイミングを配る
    struct Simulation {

        private(set) var states: [PeerID: State] = [:]
        private(set) var server = Server()

        private let machines: [PeerID: CohabitantRegistrationStateMachine]
        private var queue: [(peer: PeerID, event: CohabitantRegistrationEvent)] = []

        init(peers: [PeerID]) {
            var machines: [PeerID: CohabitantRegistrationStateMachine] = [:]
            for peer in peers {
                machines[peer] = .init(myPeerID: peer)
                states[peer] = .init(connectedPeers: Set(peers).subtracting([peer]))
            }
            self.machines = machines
        }

        /// 操作を順に行い、全端末が完了するか役割再送の上限回数に達するまで回す
        /// - Note: 操作をまとめてキューに積むと、相手へ届く前に次の操作が起きる順序になってしまうため、
        ///         1操作ずつ送受信を配信し切ってから次の操作へ進む
        mutating func run(_ operations: [(peer: PeerID, event: CohabitantRegistrationEvent)], maxTicks: Int = 10) {
            for operation in operations {
                queue.append(operation)
                drain()
            }
            var ticks = 0
            while !states.values.allSatisfy({ $0.phase == .completed }), ticks < maxTicks {
                for peer in states.keys.sorted() {
                    dispatch(peer, .tick)
                }
                drain()
                ticks += 1
            }
        }

        private mutating func drain() {
            while !queue.isEmpty {
                let (peer, event) = queue.removeFirst()
                dispatch(peer, event)
            }
        }

        private mutating func dispatch(_ peer: PeerID, _ event: CohabitantRegistrationEvent) {
            guard let machine = machines[peer], var state = states[peer] else { return }
            let effects = machine.reduce(&state, event)
            states[peer] = state
            for effect in effects {
                handle(effect, from: peer)
            }
        }

        private mutating func handle(_ effect: CohabitantRegistrationEffect, from sender: PeerID) {
            switch effect {
            case let .send(message, targets):
                for target in targets.sorted() {
                    queue.append((target, .received(message, from: sender)))
                }

            case .issueInvitation:
                server.invitationIssuers.append(sender)
                queue.append((sender, .invitationIssued(token: CohabitantRegistrationSimulationTests.invitationToken)))

            case let .joinCohabitant(invitationToken):
                #expect(invitationToken == CohabitantRegistrationSimulationTests.invitationToken)
                server.joinedPeers.insert(sender)
                queue.append((sender, .cohabitantJoined))

            case .reloadAccount:
                // 全フォロワーの参加が済む前に取り直すと、リーダーのアカウントにグループIDが入っていないことがある
                #expect(server.joinedPeers == Set(states.keys).subtracting([sender]))
                server.reloadedPeers.append(sender)
                queue.append((sender, .cohabitantJoined))

            case .log:
                break
            }
        }

    }

}
