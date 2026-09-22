//
//  CohabitantRegistrationState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

/// P2Pでの同居人登録の状態
/// - Note: 状態の変更は`CohabitantRegistrationStateMachine`だけが行う。
///         画面への指示（アラート・閉じる要求）もこの状態に載せ、外部I/Oだけを`CohabitantRegistrationEffect`にしている
public struct CohabitantRegistrationState: Equatable, Sendable {

    public typealias PeerID = CohabitantRegistrationPeerID

    public var phase: Phase
    /// セッションで接続中のメンバー
    public var connectedPeers: Set<PeerID>
    /// 表示中のアラート
    public var alert: Alert?
    /// 登録処理を続行できず、画面を閉じる必要があるかどうか
    public var isDismissRequested: Bool

    public init(
        phase: Phase = .scanning(.init()),
        connectedPeers: Set<PeerID> = [],
        alert: Alert? = nil,
        isDismissRequested: Bool = false
    ) {
        self.phase = phase
        self.connectedPeers = connectedPeers
        self.alert = alert
        self.isDismissRequested = isDismissRequested
    }

}

public extension CohabitantRegistrationState {

    enum Phase: Equatable, Sendable {

        /// 同居人となるメンバーを探している状態
        case scanning(Scanning)
        /// 同居人を登録する処理を行っている状態
        case processing(Processing)
        /// 同居人の登録が完了
        case completed

    }

    struct Scanning: Equatable, Sendable {

        /// 自分が登録開始を宣言済みかどうか
        public var isConfirmed: Bool
        /// 登録開始を宣言済みのメンバー
        public var confirmedPeers: Set<PeerID>

        public init(isConfirmed: Bool = false, confirmedPeers: Set<PeerID> = []) {
            self.isConfirmed = isConfirmed
            self.confirmedPeers = confirmedPeers
        }

    }

    struct Processing: Equatable, Sendable {

        public var role: Role
        /// 役割の通知が届いているメンバー
        /// - Note: 接続中の全メンバーと一致するまで、自分の役割を定期的に送り続ける
        public var confirmedRolePeers: Set<PeerID>

        public init(role: Role, confirmedRolePeers: Set<PeerID> = []) {
            self.role = role
            self.confirmedRolePeers = confirmedRolePeers
        }

        public var isLead: Bool {
            if case .lead = role { return true }
            return false
        }

    }

    enum Role: Equatable, Sendable {

        /// 同居人レコードを作成し、同居人IDを配る側
        case lead(Lead)
        /// 同居人IDを受け取って自分のアカウントに保存する側
        case follower(Follower)

    }

    struct Lead: Equatable, Sendable {

        /// フォロワーから受け取ったアカウントID
        public var followerAccountIds: Set<String>
        /// 登録完了の通知が届いているメンバー
        public var completedPeers: Set<PeerID>
        /// 採番した同居人ID
        public var cohabitantId: String?

        public init(
            followerAccountIds: Set<String> = [],
            completedPeers: Set<PeerID> = [],
            cohabitantId: String? = nil
        ) {
            self.followerAccountIds = followerAccountIds
            self.completedPeers = completedPeers
            self.cohabitantId = cohabitantId
        }

    }

    struct Follower: Equatable, Sendable {

        /// リーダーのメンバー
        public var leadPeer: PeerID?
        /// 自分のアカウントへの保存まで済んだ同居人ID
        public var registeredCohabitantId: String?

        public init(leadPeer: PeerID? = nil, registeredCohabitantId: String? = nil) {
            self.leadPeer = leadPeer
            self.registeredCohabitantId = registeredCohabitantId
        }

    }

    enum Alert: Equatable, Sendable {

        /// 通信中のメンバーが登録をキャンセルした
        case rejectedByPeer
        /// メンバー確定の通知を送れなかった
        case sendFailed
        /// 登録処理中に接続状態が変わった（リーダーの重複も含む）。閉じるとメンバーの選び直しに戻る
        case connectionError
        /// 同居人の登録に失敗した。閉じると登録画面を終了する
        case registrationFailed

    }

}
