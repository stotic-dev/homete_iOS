//
//  CohabitantRegistrationStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// P2Pでの同居人登録のディスパッチャ
///
/// 画面・セッションから受け取ったイベントを`CohabitantRegistrationStateMachine`に流し、
/// 返ってきた外部I/O（送信・Firestore・Analytics）を実行して結果をイベントとして戻す。
/// 状態遷移の判断はすべて状態機械側にあり、このクラスはI/Oの実行だけを担う
@MainActor
@Observable
public final class CohabitantRegistrationStore {

    public private(set) var state: CohabitantRegistrationState

    private let stateMachine: CohabitantRegistrationStateMachine

    // MARK: Dependencies

    private let messageSender: any CohabitantRegistrationMessageSender
    private let cohabitantClient: CohabitantClient
    private let analyticsClient: AnalyticsClient
    private let accountStore: AccountStore

    public init(
        myPeerID: CohabitantRegistrationPeerID,
        myAccountId: String,
        messageSender: any CohabitantRegistrationMessageSender,
        cohabitantClient: CohabitantClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountStore: AccountStore = .init(),
        makeCohabitantId: @escaping @Sendable () -> String = { UUID().uuidString },
        initialState: CohabitantRegistrationState = .init()
    ) {
        stateMachine = .init(
            myPeerID: myPeerID,
            myAccountId: myAccountId,
            makeCohabitantId: makeCohabitantId
        )
        state = initialState
        self.messageSender = messageSender
        self.cohabitantClient = cohabitantClient
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

        case let .registerCohabitant(cohabitant):
            Task {
                do {
                    try await cohabitantClient.register(cohabitant)
                    send(.cohabitantRegistered)
                } catch {
                    send(.cohabitantRegistrationFailed)
                }
            }

        case let .saveCohabitantId(cohabitantId):
            Task {
                do {
                    try await accountStore.registerCohabitantId(cohabitantId)
                    send(.cohabitantIdSaved(cohabitantId))
                } catch {
                    send(.cohabitantIdSaveFailed)
                }
            }

        case let .log(action):
            analyticsClient.log(.cohabitantRegistration(action))
        }
    }

}
