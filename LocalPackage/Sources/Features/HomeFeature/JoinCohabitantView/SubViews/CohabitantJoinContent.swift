//
//  CohabitantJoinContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 招待リンク参加画面の内容
///
/// 状態は引数で受け取り、Storeの取得完了を待たずに各状態を描画できるようにする。
/// `CohabitantJoinView` は表示直後に `.task` で招待情報の取得を始めるため、
/// 画面のPreviewをそのまま撮ると常に取得中（スピナー）になり、確認画面の見た目をVRTで検証できない。
struct CohabitantJoinContent: View {

    let state: CohabitantJoinState
    let onTapJoin: () -> Void
    let onTapClose: () -> Void

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    onTapClose()
                }
            }
    }

}

// MARK: UI定義

private extension CohabitantJoinContent {

    @ViewBuilder
    var content: some View {
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
                onTapClose()
            }
            .hideNavigationBar()

        case .alreadyMember:
            CohabitantJoinAlreadyMemberView {
                onTapClose()
            }
            .contentPadding()

        case let .failed(failure):
            CohabitantJoinFailureView(failure: failure) {
                onTapClose()
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
                onTapClose()
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

private extension View {

    /// 招待リンク参加画面の基本の余白
    func contentPadding() -> some View {
        padding(.horizontal, .space16)
            .padding(.vertical, .space24)
    }

}

#Preview("CohabitantJoinContent_確認") {
    NavigationStack {
        CohabitantJoinContent(state: .confirming(.preview), onTapJoin: {}, onTapClose: {})
    }
}

#Preview("CohabitantJoinContent_確認_招待者名なし") {
    NavigationStack {
        CohabitantJoinContent(
            state: .confirming(.init(inviterName: nil, expiresAt: .init(timeIntervalSince1970: 0))),
            onTapJoin: {},
            onTapClose: {}
        )
    }
}

// スピナーは撮影ごとに回転角が変わりVRTがフレーキーになるため、スナップショットの対象から外す

#Preview("CohabitantJoinContent_取得中") {
    NavigationStack {
        CohabitantJoinContent(state: .loading, onTapJoin: {}, onTapClose: {})
    }
    #if canImport(Prefire)
    .prefireIgnored()
    #endif
}

#Preview("CohabitantJoinContent_参加中") {
    NavigationStack {
        CohabitantJoinContent(state: .processing, onTapJoin: {}, onTapClose: {})
    }
    #if canImport(Prefire)
    .prefireIgnored()
    #endif
}
