//
//  CohabitantRegistrationSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import Combine
import HometeDomain
import HometeUI
import MultipeerConnectivity
import SwiftUI

/// P2Pセッションの出来事を`CohabitantRegistrationStore`のイベントへ変換し、状態に応じた画面を出し分けるView
/// - Note: 登録の進め方（遷移・送信・保存）の判断は`CohabitantRegistrationStateMachine`が持つ。
///         このViewはセッションと画面操作をイベントに写し、返ってきた状態を描画するだけに留める
struct CohabitantRegistrationSession: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.connectedPeers) var connectedPeers
    @Environment(\.p2pSessionReceiveData) var receiveData

    let store: CohabitantRegistrationStore
    let session: MCSession?

    /// 役割の通知を送り直す間隔
    /// - Note: 相手が登録処理に入る前に送った通知は届かないため、相手からの返答が来るまで送り続ける
    private let roleNotificationTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            switch store.state.phase {
            case let .scanning(scanning):
                P2PScanner(serviceType: .register, session: session) {
                    CohabitantRegistrationScanningStateView(
                        scanning: scanning,
                        store: store,
                        scannerController: $0
                    )
                }
                .transition(.push(from: .trailing))

            case .processing:
                CohabitantRegistrationProcessingView()
                    .transition(.push(from: .trailing))

            case .completed:
                CohabitantCompletionView(
                    title: "登録が完了しました！",
                    message: "これからは、あなたとパートナーの家事を分担し、協力していくことができます。"
                ) {
                    dismiss()
                }
                .hideNavigationBar()
                .transition(.push(from: .trailing))
            }
        }
        .animation(.spring, value: store.state.phase)
        .cohabitantRegistrationAlert(store: store)
        .onChange(of: connectedPeers, initial: true) { _, newValue in
            store.send(.peersChanged(Set(newValue.map { CohabitantRegistrationPeerID(displayName: $0.displayName) })))
        }
        .onChange(of: receiveData) { _, newValue in
            guard let newValue else { return }
            store.send(
                .received(
                    CohabitantRegistrationMessage(newValue.body),
                    from: .init(displayName: newValue.sender.displayName)
                )
            )
        }
        .onReceive(roleNotificationTimer) { _ in
            store.send(.tick)
        }
        .onChange(of: store.state.isDismissRequested) {
            guard store.state.isDismissRequested else { return }
            dismiss()
        }
    }

}

private extension View {

    /// 登録処理で発生したエラーのアラート
    /// - Note: アラートを閉じた後の進み方（選び直しに戻す・画面を閉じる）は状態機械が決めるため、
    ///         ここでは閉じたことだけを伝える
    func cohabitantRegistrationAlert(store: CohabitantRegistrationStore) -> some View {
        alert(
            store.state.alert?.title ?? "",
            isPresented: .init(
                get: { store.state.alert != nil },
                set: { isPresented in
                    guard !isPresented else { return }
                    store.send(.userDismissedAlert)
                }
            )
        ) {
            Button("OK") {}
        } message: {
            if let message = store.state.alert?.message {
                Text(message)
            }
        }
    }

}

private extension CohabitantRegistrationState.Alert {

    var title: String {
        switch self {
        case .rejectedByPeer:
            "通信中のメンバーがキャンセルしました"

        case .sendFailed, .connectionError:
            "接続エラー"

        case .registrationFailed:
            "登録に失敗しました"
        }
    }

    var message: String? {
        switch self {
        case .rejectedByPeer:
            nil

        case .sendFailed, .connectionError:
            "お手数ですが、再度デバイスを近づけて通信を行ってください"

        case .registrationFailed:
            "お手数ですが、通信状況をご確認の上、再度接続からお試しください。"
        }
    }

}
