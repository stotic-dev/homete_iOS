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
            content(state: store?.state ?? .loading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .inlineNavigationBarTitleDisplayMode()
                .leadingToolbarItem {
                    NavigationBarButton(label: .close) {
                        dismiss()
                    }
                }
        }
        .task {
            await setupStoreAndLoad()
        }
        .trackScreenView(.cohabitantJoin)
    }

}

// MARK: UI定義

private extension CohabitantJoinView {

    @ViewBuilder
    func content(state: CohabitantJoinState) -> some View {
        switch state {
        case .loading:
            loadingContent()
                .contentPadding()

        case let .confirming(summary):
            confirmingContent(summary: summary)
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

        case .alreadyMember:
            CohabitantJoinAlreadyMemberView {
                dismiss()
            }
            .contentPadding()

        case let .failed(failure):
            CohabitantJoinFailureView(failure: failure) {
                dismiss()
            }
            .contentPadding()
        }
    }

    func loadingContent() -> some View {
        VStack(spacing: .space16) {
            Indicator()
            Text("招待を確認しています...")
                .font(with: .body)
        }
    }

    func confirmingContent(summary: CohabitantInvitationSummary) -> some View {
        VStack(spacing: .space16) {
            confirmingTitle(inviterName: summary.inviterName)
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

    /// 招待者名の有無で見出しを切り替える
    /// - Note: クリップボード経由など誤ったリンクを拾う可能性がある経路でも、誰のグループかを目視で確認できるようにする
    @ViewBuilder
    func confirmingTitle(inviterName: String?) -> some View {
        if let inviterName, !inviterName.isEmpty {
            Text("\(inviterName)さんのグループに参加しますか？")
        } else {
            Text("グループに参加しますか？")
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
        .environment(\.appDependencies, .init(cohabitantInvitationClient: .init(fetch: { _ in
            .preview
        })))
}

#Preview("CohabitantJoinView_確認_招待者名なし") {
    CohabitantJoinView(token: "preview-token")
        .environment(AccountStore())
        .environment(\.appDependencies, .init(cohabitantInvitationClient: .init(fetch: { _ in
            .init(inviterName: nil, expiresAt: .init(timeIntervalSince1970: 0))
        })))
}

#Preview("CohabitantJoinView_取得中") {
    CohabitantJoinView(token: "preview-token")
        .environment(AccountStore())
        .environment(\.appDependencies, .init(cohabitantInvitationClient: .init(fetch: { _ in
            try await Task.sleep(for: .seconds(60))
            return .preview
        })))
}

#Preview("CohabitantJoinView_期限切れ") {
    CohabitantJoinView(token: "preview-token")
        .environment(AccountStore())
        .environment(\.appDependencies, .init(cohabitantInvitationClient: .init(fetch: { _ in
            throw CohabitantInvitationError.expired
        })))
}
