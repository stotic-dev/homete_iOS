//
//  CohabitantJoinView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 招待リンクから同居人グループに参加する画面
///
/// Storeの生成と招待情報の取得を担い、見た目は `CohabitantJoinContent` に状態を渡して描画する。
/// 表示直後に取得を始めるため、この画面自体はPreview（VRT）の対象にしない（常に取得中の見た目になる）。
public struct CohabitantJoinView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.appDependencies.cohabitantInvitationClient) var cohabitantInvitationClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(AccountStore.self) var accountStore

    @State var store: CohabitantJoinStore?

    let token: String

    public init(token: String) {
        self.token = token
    }

    public var body: some View {
        NavigationStack {
            CohabitantJoinContent(
                state: store?.state ?? .loading,
                onTapJoin: onTapJoin,
                onTapClose: { dismiss() }
            )
        }
        .task {
            await setupStoreAndLoad()
        }
        .trackScreenView(.cohabitantJoin)
    }

}

// MARK: プレゼンテーションロジック

private extension CohabitantJoinView {

    func setupStoreAndLoad() async {
        if store == nil {
            store = .init(
                token: token,
                cohabitantInvitationClient: cohabitantInvitationClient,
                analyticsClient: analyticsClient,
                accountStore: accountStore
            )
        }
        await store?.load()
    }

    func onTapJoin() {
        guard let store else { return }
        Task {
            await store.join()
        }
    }

}
