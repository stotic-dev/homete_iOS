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
    static let cohabitantId = "cohabitant-id"

    @Test("2台とも宣言したら、名前順が最小の端末がレコードを作成し、両端末とも同居人IDを保存して完了する")
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
        let expectedRegistered = [CohabitantData(id: Self.cohabitantId, members: ["A_peer-account", "B_peer-account"])]
        let expectedSaved = [Self.peerA: Self.cohabitantId, Self.peerB: Self.cohabitantId]

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.registeredCohabitants == expectedRegistered)
        #expect(simulation.savedCohabitantIds == expectedSaved)
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
        let expectedRegistered = [CohabitantData(id: Self.cohabitantId, members: ["A_peer-account", "B_peer-account"])]
        let expectedSaved = [Self.peerA: Self.cohabitantId, Self.peerB: Self.cohabitantId]

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.registeredCohabitants == expectedRegistered)
        #expect(simulation.savedCohabitantIds == expectedSaved)
    }

    @Test("3台でも、リーダー1台が全員分のアカウントIDでレコードを作成して全端末が完了する")
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
        let expectedRegistered = [
            CohabitantData(id: Self.cohabitantId, members: ["A_peer-account", "B_peer-account", "C_peer-account"]),
        ]
        let expectedSaved = [
            Self.peerA: Self.cohabitantId,
            Self.peerB: Self.cohabitantId,
            Self.peerC: Self.cohabitantId,
        ]

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.registeredCohabitants == expectedRegistered)
        #expect(simulation.savedCohabitantIds == expectedSaved)
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
        let expectedRegistered = [CohabitantData(id: Self.cohabitantId, members: ["A_peer-account", "B_peer-account"])]
        let expectedSaved = [Self.peerA: Self.cohabitantId, Self.peerB: Self.cohabitantId]

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.registeredCohabitants == expectedRegistered)
        #expect(simulation.savedCohabitantIds == expectedSaved)
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
        let expectedRegistered = [CohabitantData(id: Self.cohabitantId, members: ["A_peer-account", "B_peer-account"])]
        let expectedSaved = [Self.peerA: Self.cohabitantId, Self.peerB: Self.cohabitantId]

        // Act
        simulation.run(operations)

        // Assert
        #expect(simulation.states == expectedStates)
        #expect(simulation.registeredCohabitants == expectedRegistered)
        #expect(simulation.savedCohabitantIds == expectedSaved)
    }

}

// MARK: - シミュレーション

extension CohabitantRegistrationSimulationTests {

    /// 各端末の状態機械と、端末間の送受信・非同期処理の結果を配線するインメモリのハーネス
    /// - Note: 送信は相手端末の受信イベントに、レコード作成・保存は即時成功の結果イベントに置き換える。
    ///         イベントは1本のキューでFIFOに処理し、キューが空いたら各端末へ役割再送のタイミングを配る
    struct Simulation {

        private(set) var states: [PeerID: State] = [:]
        private(set) var registeredCohabitants: [CohabitantData] = []
        private(set) var savedCohabitantIds: [PeerID: String] = [:]

        private let machines: [PeerID: CohabitantRegistrationStateMachine]
        private var queue: [(peer: PeerID, event: CohabitantRegistrationEvent)] = []

        init(peers: [PeerID]) {
            var machines: [PeerID: CohabitantRegistrationStateMachine] = [:]
            for peer in peers {
                machines[peer] = .init(
                    myPeerID: peer,
                    myAccountId: "\(peer.displayName)-account",
                    makeCohabitantId: { CohabitantRegistrationSimulationTests.cohabitantId }
                )
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

            case let .registerCohabitant(cohabitant):
                registeredCohabitants.append(cohabitant)
                queue.append((sender, .cohabitantRegistered))

            case let .saveCohabitantId(cohabitantId):
                savedCohabitantIds[sender] = cohabitantId
                queue.append((sender, .cohabitantIdSaved(cohabitantId)))

            case .log:
                break
            }
        }

    }

}
