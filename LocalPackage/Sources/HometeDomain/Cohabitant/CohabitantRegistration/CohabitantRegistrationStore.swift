//
//  CohabitantRegistrationStore.swift
//  LocalPackage
//

import Observation

/// P2Pでの同居人登録のディスパッチャ
///
/// 画面・セッションから受け取ったイベントを`CohabitantRegistrationStateMachine`に流し、
/// 返ってきた外部I/O（送信・Cloud Functions・Firestore・Analytics）を実行して結果をイベントとして戻す。
/// 状態遷移の判断はすべて状態機械側にあり、このクラスはI/Oの実行だけを担う
@MainActor
@Observable
public final class CohabitantRegistrationStore {

    public private(set) var state: CohabitantRegistrationState

    private let stateMachine: CohabitantRegistrationStateMachine

    // MARK: Dependencies

    private let messageSender: any CohabitantRegistrationMessageSender
    private let cohabitantInvitationClient: CohabitantInvitationClient
    private let analyticsClient: AnalyticsClient
    private let accountStore: AccountStore

    public init(
        myPeerID: CohabitantRegistrationPeerID,
        messageSender: any CohabitantRegistrationMessageSender,
        cohabitantInvitationClient: CohabitantInvitationClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountStore: AccountStore = .init(),
        initialState: CohabitantRegistrationState = .init()
    ) {
        stateMachine = .init(myPeerID: myPeerID)
        state = initialState
        self.messageSender = messageSender
        self.cohabitantInvitationClient = cohabitantInvitationClient
        self.analyticsClient = analyticsClient
        self.accountStore = accountStore
    }

    /// イベントを状態機械へ流し、要求された外部I/Oを実行する
    public func send(_ event: CohabitantRegistrationEvent) {
        let effects = stateMachine.reduce(&state, event)
        for effect in effects {
            perform(effect)
        }
    }

}

private extension CohabitantRegistrationStore {

    func perform(_ effect: CohabitantRegistrationEffect) {
        switch effect {
        case let .send(message, peers):
            do {
                try messageSender.send(message, to: peers)
            } catch {
                send(.sendFailed)
            }

        case .issueInvitation:
            Task {
                do {
                    let invitation = try await cohabitantInvitationClient.issue()
                    send(.invitationIssued(token: invitation.token))
                } catch {
                    send(.invitationIssueFailed)
                }
            }

        case let .joinCohabitant(invitationToken):
            Task {
                do {
                    let result = try await cohabitantInvitationClient.join(invitationToken)
                    // サーバ側でアカウントの更新まで済んでいるため、オンメモリの状態だけ揃える
                    accountStore.applyCohabitantId(result.cohabitantId)
                    send(.cohabitantJoined)
                } catch {
                    send(.cohabitantJoinFailed)
                }
            }

        case .reloadAccount:
            Task {
                // フォロワーの参加でサーバ側がグループIDを書き込んでいるので、完了を表示する前に取り込んでおく。
                // 全フォロワーから完了が届いた時点でグループは確定しているため、取り直しに失敗しても
                // 失敗扱いにはしない（失敗にするとフォロワーは完了を待ったまま取り残される）。
                // 取り込めなかった分は自分のアカウントの購読（AccountStore.startObservingIfNeeded）で反映される
                try? await accountStore.reload()
                send(.cohabitantJoined)
            }

        case let .log(action):
            analyticsClient.log(.cohabitantRegistration(action))
        }
    }

}
