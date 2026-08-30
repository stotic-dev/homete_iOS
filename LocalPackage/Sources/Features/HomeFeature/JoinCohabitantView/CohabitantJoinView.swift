//
//  CohabitantJoinView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 招待リンクから同居人グループに参加する画面
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
            content(state: store?.state ?? .confirming)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .inlineNavigationBarTitleDisplayMode()
                .leadingToolbarItem {
                    NavigationBarButton(label: .close) {
                        dismiss()
                    }
                }
        }
        .onAppear {
            setupStoreIfNeeded()
        }
    }

}

// MARK: UI定義

private extension CohabitantJoinView {

    @ViewBuilder
    func content(state: CohabitantJoinState) -> some View {
        switch state {
        case .confirming:
            confirmingContent()
                .contentPadding()

        case .processing:
            processingContent()
                .contentPadding()

        case .completed:
            // 演出を画面いっぱいに広げるため、余白はView側に持たせてナビゲーションバーも隠す
            CohabitantCompletionView(
                title: "グループに参加しました！",
                message: "これからは、グループのメンバーと家事を分担し、協力していくことができます。"
            ) {
                dismiss()
            }
            .hideNavigationBar()

        case let .failed(failure):
            CohabitantJoinFailureView(failure: failure) {
                dismiss()
            }
            .contentPadding()
        }
    }

    func confirmingContent() -> some View {
        VStack(spacing: .space16) {
            Text("グループに招待されています")
                .font(with: .headLineL)
            Text("参加すると、招待してくれた人と家事を分担・共有できるようになります。")
                .font(with: .body)
            Spacer()
            Button {
                onTapJoin()
            } label: {
                Text("参加する")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            Button {
                dismiss()
            } label: {
                Text("あとで")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }

    func processingContent() -> some View {
        VStack(spacing: .space16) {
            Indicator()
            Text("グループに参加しています...")
                .font(with: .body)
        }
    }

}

// MARK: プレゼンテーションロジック

private extension CohabitantJoinView {

    func setupStoreIfNeeded() {
        guard store == nil else { return }
        store = .init(
            token: token,
            cohabitantInvitationClient: cohabitantInvitationClient,
            analyticsClient: analyticsClient,
            accountStore: accountStore
        )
    }

    func onTapJoin() {
        guard let store else { return }
        Task {
            await store.join()
        }
    }

}

private extension View {

    /// 招待リンク参加画面の基本の余白
    func contentPadding() -> some View {
        padding(.horizontal, .space16)
            .padding(.vertical, .space24)
    }

}

#Preview("CohabitantJoinView_確認") {
    CohabitantJoinView(token: "preview-token")
        .environment(AccountStore())
}
