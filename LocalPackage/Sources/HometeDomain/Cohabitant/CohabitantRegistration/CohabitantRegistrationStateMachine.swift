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
///    - リーダー: 全フォロワーの役割が揃ったら招待トークンを発行して配り、全フォロワーの参加完了を待ってから
///      サーバー側でグループIDが書き込まれた自分のアカウントを取り直し、完了を通知する
///    - フォロワー: 招待トークンを受け取ったら自分でグループに参加し、リーダーへ完了を通知する
/// 3. completed
///
/// グループの作成・メンバーの追加はCloud Functions（`joincohabitant`）が行い、クライアントが他人のIDを
/// `Cohabitant.members`へ書くことはない。リーダーが未所属で発行した招待では、最初のフォロワーが参加した時点で
/// リーダーとの2人のグループが作られ、2人目以降のフォロワーも同じグループへ入る（ADR-0017、ADR-0040）
public struct CohabitantRegistrationStateMachine: Sendable {

    public typealias State = CohabitantRegistrationState
    public typealias Event = CohabitantRegistrationEvent
    public typealias Effect = CohabitantRegistrationEffect
    public typealias PeerID = CohabitantRegistrationPeerID

    let myPeerID: PeerID

    public init(myPeerID: PeerID) {
        self.myPeerID = myPeerID
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

        case .invitationIssued, .invitationIssueFailed, .cohabitantJoined, .cohabitantJoinFailed:
            return reduceRegistrationResult(&state, event)
        }
    }

}

// MARK: - 各イベントの遷移

private extension CohabitantRegistrationStateMachine {

    /// 招待トークンの発行・グループへの参加の結果に対する遷移
    /// - Note: 結果は非同期で届くため、接続エラーで選び直した後に前の試行の結果が届くことがある。
    ///         登録処理中でなければ捨て、同じ結果が重なっても二重に進めない
    func reduceRegistrationResult(_ state: inout State, _ event: Event) -> [Effect] {
        guard case .processing = state.phase else { return [] }

        switch event {
        case let .invitationIssued(token):
            guard case var .processing(processing) = state.phase,
                  case var .lead(lead) = processing.role,
                  lead.invitationToken == nil else { return [] }
            lead.invitationToken = token
            processing.role = .lead(lead)
            state.phase = .processing(processing)
            return [.send(.init(type: .shareInvitation(token: token)), to: state.connectedPeers)]

        case .invitationIssueFailed, .cohabitantJoinFailed:
            state.alert = .registrationFailed
            return [.log(.completed(method: .p2p, isSuccess: false))]

        case .cohabitantJoined:
            return reduceCohabitantJoined(&state)

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
            guard !message.isFromOutdatedPeer else {
                // 旧バージョンのアプリはリーダーがグループを作る方式のままで、招待トークンを解読できずに落ちる。
                // 登録処理に進む前に止め、相手にも宣言の取り消しを伝えて選び直しの状態に戻してもらう。
                // 取り消しを他の新しい端末にまで送ると、相手のアップデートの案内がキャンセルのアラートで上書きされる。
                // 他の新しい端末も旧端末の宣言を受けて自分で選び直しに戻るため、旧端末にだけ送る
                state.phase = .scanning(.init())
                state.alert = .outdatedPeer
                return [.send(.init(type: .fixedMember(isOK: false)), to: [sender])]
            }
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
            guard !role.isLeader else {
                // 相手もリーダーを名乗っている＝各デバイスの接続状況が食い違い、リーダーが2人選ばれた状態。
                // このまま待っても役割が揃わないため、接続エラーとしてメンバーの選び直しに戻す
                state.alert = .connectionError
                return []
            }
            let (inserted, _) = processing.confirmedRolePeers.insert(sender)
            // 全員の役割が分かった時点で、招待トークンを発行する。
            // 役割の通知は届くたびに同じメンバーで重複するため、最後の1人が揃った1回だけ発行する
            guard inserted,
                  processing.confirmedRolePeers == state.connectedPeers,
                  lead.invitationToken == nil else { return [] }
            return [.issueInvitation]
        }

        if message.isComplete ?? false {
            let (inserted, _) = lead.completedPeers.insert(sender)
            // 他のデバイス全てから参加完了の通知が来たら、サーバー側で書き込まれた自分のアカウントを取り直す
            guard inserted,
                  lead.completedPeers == state.connectedPeers,
                  lead.invitationToken != nil else { return [] }
            return [.reloadAccount]
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
            // すでにグループへの参加まで済んでいたら、完了メッセージを送信する
            guard follower.hasJoined else { return [] }
            return [.send(.init(type: .complete), to: [sender])]
        }

        if let invitationToken = message.invitationToken {
            // 招待トークンを共有してくるのはリーダーだけなので、送信元をリーダーとして扱う。
            // リーダーは全員の役割が揃った時点で役割の通知をやめるため、こちらの役割通知が
            // 相手の最初の通知より先に届くと、役割の通知だけが一度も来ないまま招待トークンが届くことがある
            if follower.leadPeer == nil {
                follower.leadPeer = sender
                processing.confirmedRolePeers.insert(sender)
            }
            guard !follower.hasJoined else { return [] }
            return [.joinCohabitant(invitationToken: invitationToken)]
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

        case .sendFailed, .outdatedPeer, nil:
            break
        }
        return []
    }

    func reduceCohabitantJoined(_ state: inout State) -> [Effect] {
        guard case var .processing(processing) = state.phase else { return [] }
        let completedLog: Effect = .log(.completed(method: .p2p, isSuccess: true))

        switch processing.role {
        case .lead:
            // 自分のアカウントにグループIDが反映されてから、他デバイスに完了を伝える
            state.phase = .completed
            return [completedLog, .send(.init(type: .complete), to: state.connectedPeers)]

        case var .follower(follower):
            guard !follower.hasJoined else { return [] }
            follower.hasJoined = true
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
    /// - リーダー: フォロワーの役割が全員分揃えば、あとは招待トークンを配るだけなので止めてよい
    /// - フォロワー: 招待トークンの共有はリーダーが自分の役割を受け取った証拠なので、参加が済むまで送り続ける
    func needsRoleNotification(_ processing: State.Processing, connectedPeers: Set<PeerID>) -> Bool {
        switch processing.role {
        case .lead:
            processing.confirmedRolePeers != connectedPeers

        case let .follower(follower):
            !follower.hasJoined
        }
    }

    /// 他デバイスへ通知する役割
    func role(of processing: State.Processing) -> CohabitantRegistrationRole {
        switch processing.role {
        case .lead:
            .lead

        case .follower:
            .follower
        }
    }

}
