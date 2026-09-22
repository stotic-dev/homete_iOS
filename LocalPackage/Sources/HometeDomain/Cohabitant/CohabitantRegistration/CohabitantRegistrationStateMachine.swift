//
//  CohabitantRegistrationStateMachine.swift
//  LocalPackage
//

/// P2Pでの同居人登録の状態遷移
///
/// 外部I/Oを持たない純粋関数として遷移を定義し、通信順序や接続状態の組み合わせをユニットテストで固定する。
/// 各端末の流れは次の通り。
///
/// 1. scanning: 接続中の全メンバーが「登録を開始する」を宣言したら、`displayName`が最小のメンバーをリーダーにして処理へ進む
/// 2. processing: 相手からの返答が返ってくるまで自分の役割を定期送信する。
///    - リーダー: フォロワーのアカウントIDが揃ったら同居人レコードを作成して同居人IDを配り、
///      全フォロワーの保存完了を待ってから自分のアカウントに保存し、完了を通知する
///    - フォロワー: 同居人IDを受け取ったら自分のアカウントに保存し、リーダーへ完了を通知する
/// 3. completed
public struct CohabitantRegistrationStateMachine: Sendable {

    public typealias State = CohabitantRegistrationState
    public typealias Event = CohabitantRegistrationEvent
    public typealias Effect = CohabitantRegistrationEffect
    public typealias PeerID = CohabitantRegistrationPeerID

    let myPeerID: PeerID
    let myAccountId: String
    /// 同居人IDの採番
    /// - Note: テストで遷移結果を決定的にするため差し替えられるようにしている
    let makeCohabitantId: @Sendable () -> String

    public init(
        myPeerID: PeerID,
        myAccountId: String,
        makeCohabitantId: @escaping @Sendable () -> String
    ) {
        self.myPeerID = myPeerID
        self.myAccountId = myAccountId
        self.makeCohabitantId = makeCohabitantId
    }

    /// 状態を進め、実行すべき外部I/Oを返す
    public func reduce(_ state: inout State, _ event: Event) -> [Effect] {
        switch event {
        case let .peersChanged(peers):
            return reducePeersChanged(&state, peers: peers)

        case let .received(message, sender):
            return reduceReceived(&state, message: message, sender: sender)

        case .sendFailed:
            // 登録処理中の送信失敗は切断に伴う`peersChanged`で接続エラーとして拾うため、ここでは扱わない
            if case .scanning = state.phase {
                state.alert = .sendFailed
            }
            return []

        case let .userConfirmedMembers(isOK):
            return reduceUserConfirmedMembers(&state, isOK: isOK)

        case .userDismissedAlert:
            return reduceUserDismissedAlert(&state)

        case .tick:
            guard case let .processing(processing) = state.phase,
                  needsRoleNotification(processing, connectedPeers: state.connectedPeers) else { return [] }
            return [.send(.init(type: .preRegistration(role: role(of: processing))), to: state.connectedPeers)]

        case .cohabitantRegistered, .cohabitantRegistrationFailed, .cohabitantIdSaved, .cohabitantIdSaveFailed:
            return reduceRegistrationResult(&state, event)
        }
    }

}

// MARK: - 各イベントの遷移

private extension CohabitantRegistrationStateMachine {

    /// 同居人レコードの作成・同居人IDの保存の結果に対する遷移
    func reduceRegistrationResult(_ state: inout State, _ event: Event) -> [Effect] {
        switch event {
        case .cohabitantRegistered:
            guard case let .processing(processing) = state.phase,
                  case let .lead(lead) = processing.role,
                  let cohabitantId = lead.cohabitantId else { return [] }
            return [.send(.init(type: .shareCohabitantId(id: cohabitantId)), to: state.connectedPeers)]

        case .cohabitantRegistrationFailed, .cohabitantIdSaveFailed:
            state.alert = .registrationFailed
            return [.log(.completed(method: .p2p, isSuccess: false))]

        case let .cohabitantIdSaved(cohabitantId):
            return reduceCohabitantIdSaved(&state, cohabitantId: cohabitantId)

        default:
            return []
        }
    }

    func reducePeersChanged(_ state: inout State, peers: Set<PeerID>) -> [Effect] {
        let previousPeers = state.connectedPeers
        state.connectedPeers = peers

        var effects: [Effect] = []
        if previousPeers.isEmpty, !peers.isEmpty {
            effects.append(.log(.peerFound))
        }

        switch state.phase {
        case .scanning:
            // 接続が全て切れたら宣言は無効になるため、自分・相手とも最初からやり直す
            if peers.isEmpty {
                state.phase = .scanning(.init())
            }

        case .processing:
            // 処理中にメンバーが増減すると役割や完了の集計が成立しないため、接続エラーとして選び直しに戻す
            state.alert = .connectionError

        case .completed:
            break
        }
        return effects
    }

    func reduceReceived(_ state: inout State, message: CohabitantRegistrationMessage, sender: PeerID) -> [Effect] {
        switch state.phase {
        case var .scanning(scanning):
            guard let isFixedMember = message.isFixedMember else { return [] }
            if isFixedMember {
                scanning.confirmedPeers.insert(sender)
            } else {
                // 登録メンバーが拒否した場合は、再度メンバーを選び直す
                scanning.confirmedPeers = []
                state.alert = .rejectedByPeer
            }
            state.phase = .scanning(scanning)
            transitionToProcessingIfReady(&state)
            return []

        case var .processing(processing):
            let effects: [Effect]
            switch processing.role {
            case var .lead(lead):
                effects = reduceLeadReceived(&state, &processing, &lead, message: message, sender: sender)
                processing.role = .lead(lead)

            case var .follower(follower):
                effects = reduceFollowerReceived(&state, &processing, &follower, message: message, sender: sender)
                processing.role = .follower(follower)
            }
            // フォロワーからの完了通知で完了に遷移済みの場合は、処理中の状態を書き戻さない
            if case .processing = state.phase {
                state.phase = .processing(processing)
            }
            return effects

        case .completed:
            return []
        }
    }

    func reduceLeadReceived(
        _ state: inout State,
        _ processing: inout State.Processing,
        _ lead: inout State.Lead,
        message: CohabitantRegistrationMessage,
        sender: PeerID
    ) -> [Effect] {
        if let role = message.memberRole {
            guard let accountId = role.accountId else {
                // 相手もリーダーを名乗っている＝各デバイスの接続状況が食い違い、リーダーが2人選ばれた状態。
                // このまま待っても役割が揃わないため、接続エラーとしてメンバーの選び直しに戻す
                state.alert = .connectionError
                return []
            }
            lead.followerAccountIds.insert(accountId)
            let (inserted, _) = processing.confirmedRolePeers.insert(sender)
            // 全員の役割が分かった時点で、同居人のレコードを作成する
            guard inserted,
                  processing.confirmedRolePeers == state.connectedPeers,
                  lead.cohabitantId == nil else { return [] }
            let cohabitantId = makeCohabitantId()
            lead.cohabitantId = cohabitantId
            let members = [myAccountId] + lead.followerAccountIds.sorted()
            return [.registerCohabitant(.init(id: cohabitantId, members: members))]
        }

        if message.isComplete ?? false {
            let (inserted, _) = lead.completedPeers.insert(sender)
            // 他のデバイス全てから登録完了通知が来たら、自分のアカウントへ保存する
            guard inserted,
                  lead.completedPeers == state.connectedPeers,
                  let cohabitantId = lead.cohabitantId else { return [] }
            return [.saveCohabitantId(cohabitantId)]
        }

        return []
    }

    func reduceFollowerReceived(
        _ state: inout State,
        _ processing: inout State.Processing,
        _ follower: inout State.Follower,
        message: CohabitantRegistrationMessage,
        sender: PeerID
    ) -> [Effect] {
        if message.memberRole?.isLeader ?? false {
            follower.leadPeer = sender
            processing.confirmedRolePeers.insert(sender)
            // すでに同居人IDの保存まで済んでいたら、完了メッセージを送信する
            guard follower.registeredCohabitantId != nil else { return [] }
            return [.send(.init(type: .complete), to: [sender])]
        }

        if let cohabitantId = message.cohabitantId {
            // 同居人IDを共有してくるのはリーダーだけなので、送信元をリーダーとして扱う。
            // リーダーは全員の役割が揃った時点で役割の通知をやめるため、こちらの役割通知が
            // 相手の最初の通知より先に届くと、役割の通知だけが一度も来ないまま同居人IDが届くことがある
            if follower.leadPeer == nil {
                follower.leadPeer = sender
                processing.confirmedRolePeers.insert(sender)
            }
            return [.saveCohabitantId(cohabitantId)]
        }

        if message.isComplete ?? false {
            state.phase = .completed
        }
        return []
    }

    func reduceUserConfirmedMembers(_ state: inout State, isOK: Bool) -> [Effect] {
        guard case var .scanning(scanning) = state.phase else { return [] }
        if isOK {
            scanning.isConfirmed = true
        } else {
            // 相手側はキャンセルを受け取ると宣言をやり直すため、受け取っていた宣言も忘れる
            scanning.confirmedPeers = []
        }
        state.phase = .scanning(scanning)
        transitionToProcessingIfReady(&state)
        return [.send(.init(type: .fixedMember(isOK: isOK)), to: state.connectedPeers)]
    }

    func reduceUserDismissedAlert(_ state: inout State) -> [Effect] {
        defer { state.alert = nil }
        switch state.alert {
        case .rejectedByPeer:
            guard case var .scanning(scanning) = state.phase else { return [] }
            scanning.isConfirmed = false
            state.phase = .scanning(scanning)

        case .connectionError:
            state.phase = .scanning(.init())

        case .registrationFailed:
            state.isDismissRequested = true

        case .sendFailed, nil:
            break
        }
        return []
    }

    func reduceCohabitantIdSaved(_ state: inout State, cohabitantId: String) -> [Effect] {
        guard case var .processing(processing) = state.phase else { return [] }
        let completedLog: Effect = .log(.completed(method: .p2p, isSuccess: true))

        switch processing.role {
        case .lead:
            // 自分のアカウントへの保存が済んでから、他デバイスに完了を伝える
            state.phase = .completed
            return [completedLog, .send(.init(type: .complete), to: state.connectedPeers)]

        case var .follower(follower):
            follower.registeredCohabitantId = cohabitantId
            processing.role = .follower(follower)
            state.phase = .processing(processing)
            // リーダーがまだ分からない場合は、役割の通知が届いた時点で完了を送る
            guard let leadPeer = follower.leadPeer else { return [completedLog] }
            return [completedLog, .send(.init(type: .complete), to: [leadPeer])]
        }
    }

}

// MARK: - 補助

private extension CohabitantRegistrationStateMachine {

    /// 自分が登録開始を宣言済みで、かつ接続中の全メンバーの宣言が届いている場合だけ登録処理に移行する
    func transitionToProcessingIfReady(_ state: inout State) {
        guard case let .scanning(scanning) = state.phase,
              scanning.isConfirmed,
              !state.connectedPeers.isEmpty,
              scanning.confirmedPeers == state.connectedPeers else { return }

        let isLead = ([myPeerID] + state.connectedPeers).min() == myPeerID
        let role: State.Role = isLead ? .lead(.init()) : .follower(.init())
        state.phase = .processing(.init(role: role))
    }

    /// 自分の役割を送り続ける必要があるかどうか
    ///
    /// 相手の役割が届いたことは、自分の役割が相手に届いたことを意味しない。
    /// 相手が登録処理に入る前に送った役割は捨てられるため、停止の条件は「相手からの返答が来たか」で判断する。
    /// - リーダー: フォロワーの役割（＝アカウントID）が全員分揃えば、あとは同居人IDを配るだけなので止めてよい
    /// - フォロワー: 同居人IDの共有はリーダーが自分の役割を受け取った証拠なので、それが済むまで送り続ける
    func needsRoleNotification(_ processing: State.Processing, connectedPeers: Set<PeerID>) -> Bool {
        switch processing.role {
        case .lead:
            processing.confirmedRolePeers != connectedPeers

        case let .follower(follower):
            follower.registeredCohabitantId == nil
        }
    }

    /// 他デバイスへ通知する役割
    func role(of processing: State.Processing) -> CohabitantRegistrationRole {
        switch processing.role {
        case .lead:
            .lead

        case .follower:
            .follower(accountId: myAccountId)
        }
    }

}
