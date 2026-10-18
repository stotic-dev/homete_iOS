//
//  NotRegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeDomain
import HometeUI
import SwiftUI

/// グループ未参加のホームに出す「家事を始める前に」のやることリスト
///
/// 並べるのは未完了の項目だけ。パートナー登録と、匿名のときだけApple連携を出す。
/// 相手が参加すると`Account.cohabitantId`が入りホームが切り替わるため、パートナー登録を完了済みとして出すことはない。
struct NotRegisteredContent: View {

    /// 匿名のまま（Appleアカウントと未連携）か
    let isAnonymous: Bool
    /// 招待を送っていて、相手の参加を待っているか
    let isWaitingForPartner: Bool
    /// クリップボードにコピーされた招待リンクの案内状態
    let pasteboardInvitationState: PasteboardInvitationStore.State
    let onTapRegisterPartner: () -> Void
    let onTapResendInvitation: () -> Void
    let onTapLinkAccount: () -> Void
    /// 「招待リンクを確認する」タップ時の処理
    let onTapCheckPasteboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                header
                VStack(spacing: .space16) {
                    partnerRow
                    if isAnonymous {
                        todoRow(
                            title: .localized("Appleアカウントで保存する"),
                            description: .localized("機種変更しても、家事の記録を引き継げます"),
                            buttonTitle: .localized("保存する"),
                            action: onTapLinkAccount
                        )
                    }
                }
                PasteboardInvitationBanner(state: pasteboardInvitationState, onTapCheck: onTapCheckPasteboard)
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // グループ参加済みのダッシュボードとそろえて、画面の地はミルク色にしてカードを浮かせる
        .background(.backgroundScreen)
    }

}

// MARK: UI定義

private extension NotRegisteredContent {

    var header: some View {
        VStack(spacing: .space16) {
            HometteView(.cheer, size: .medium)
            VStack(spacing: .space8) {
                Text("家事を始める前に", bundle: #bundle)
                    .font(with: .headLineM)
                Text("完了すると、家事の記録と共有ができるようになります", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    var partnerRow: some View {
        if isWaitingForPartner {
            todoRow(
                title: .localized("パートナーの参加を待っています"),
                description: .localized("送った招待リンクから参加すると、家事を分け合えます"),
                buttonTitle: .localized("もう一度送る"),
                action: onTapResendInvitation
            )
        } else {
            todoRow(
                title: .localized("パートナーを登録する"),
                description: .localized("パートナーを招待すると、家事を分け合えます"),
                buttonTitle: .localized("登録する"),
                action: onTapRegisterPartner
            )
        }
    }

    func todoRow(
        title: LocalizedStringResource,
        description: LocalizedStringResource,
        buttonTitle: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: .space16) {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.iconDecorative)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: .space4) {
                Text(title)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Text(description)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                action()
            } label: {
                Text(buttonTitle)
                    .fixedSize()
            }
            .subPrimaryButtonStyle()
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius20)
                .fill(.backgroundCard)
        }
    }

}

// Appleでログイン済みで、パートナー登録の1項目だけが並ぶ
#Preview {
    NotRegisteredContent(
        isAnonymous: false,
        isWaitingForPartner: false,
        pasteboardInvitationState: .idle,
        onTapRegisterPartner: {},
        onTapResendInvitation: {},
        onTapLinkAccount: {},
        onTapCheckPasteboard: {}
    )
}

#Preview("NotRegisteredContent_匿名") {
    NotRegisteredContent(
        isAnonymous: true,
        isWaitingForPartner: false,
        pasteboardInvitationState: .idle,
        onTapRegisterPartner: {},
        onTapResendInvitation: {},
        onTapLinkAccount: {},
        onTapCheckPasteboard: {}
    )
}

#Preview("NotRegisteredContent_参加を待っている") {
    NotRegisteredContent(
        isAnonymous: true,
        isWaitingForPartner: true,
        pasteboardInvitationState: .idle,
        onTapRegisterPartner: {},
        onTapResendInvitation: {},
        onTapLinkAccount: {},
        onTapCheckPasteboard: {}
    )
}

#Preview("NotRegisteredContent_招待リンクの案内あり") {
    NotRegisteredContent(
        isAnonymous: false,
        isWaitingForPartner: false,
        pasteboardInvitationState: .suggesting,
        onTapRegisterPartner: {},
        onTapResendInvitation: {},
        onTapLinkAccount: {},
        onTapCheckPasteboard: {}
    )
}
