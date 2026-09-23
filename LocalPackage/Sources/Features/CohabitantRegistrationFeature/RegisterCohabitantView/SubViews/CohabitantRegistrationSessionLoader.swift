//
//  CohabitantRegistrationSessionLoader.swift
//  LocalPackage
//

import HometeDomain
import MultipeerConnectivity
import SwiftUI

/// 自分のピアIDが決まってから`CohabitantRegistrationStore`を1つだけ作るView
/// - Note: ピアIDはセッションを張った後に決まるため、Storeの生成を待ち合わせる場所として分けている
struct CohabitantRegistrationSessionLoader: View {

    @Environment(\.myPeerID) var myPeerID
    @Environment(\.p2pSessionProxy) var p2pSessionProxy
    @Environment(\.cohabitantRegistrationStoreFactory) var storeFactory

    @State var store: CohabitantRegistrationStore?

    let session: MCSession?

    var body: some View {
        ZStack {
            if let store {
                CohabitantRegistrationSession(store: store, session: session)
            }
        }
        // ピアIDとセッションはどちらが先に反映されるか決まらないため、揃ったタイミングで一度だけ作る
        .onChange(of: myPeerID, initial: true) { _, _ in
            makeStoreIfNeeded()
        }
        .onChange(of: p2pSessionProxy == nil) {
            makeStoreIfNeeded()
        }
    }

}

private extension CohabitantRegistrationSessionLoader {

    func makeStoreIfNeeded() {
        guard store == nil,
              let myPeerID,
              let p2pSessionProxy else { return }
        store = storeFactory.make(.init(displayName: myPeerID.displayName), p2pSessionProxy)
    }

}

/// `CohabitantRegistrationStore`の生成方法
/// - Note: ピアIDとセッションが決まるまで生成できないため、依存を束ねた生成手順だけを上位から渡す。
///         デバッグ画面はここを差し替えてFirestoreへの書き込みを止める
struct CohabitantRegistrationStoreFactory {

    let make: @MainActor (
        _ myPeerID: CohabitantRegistrationPeerID,
        _ messageSender: any CohabitantRegistrationMessageSender
    ) -> CohabitantRegistrationStore

}

extension EnvironmentValues {

    @Entry var cohabitantRegistrationStoreFactory = CohabitantRegistrationStoreFactory { myPeerID, messageSender in
        CohabitantRegistrationStore(myPeerID: myPeerID, myAccountId: "", messageSender: messageSender)
    }

}
