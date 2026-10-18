//
//  PartnerRegistrationView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでパートナーの登録方法を選ぶ画面のUI
struct PartnerRegistrationView: View {

    /// 招待リンクを使えるか。使えない環境では「招待リンクを送る」を出さない
    let isInvitationAvailable: Bool
    /// 「招待された」でクリップボードを確認したが、招待リンクが見つからなかったか
    let isInvitationNotFound: Bool
    let onTapInvite: () -> Void
    let onTapNearby: () -> Void
    let onTapInvited: () -> Void
    let onTapLater: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                header
                VStack(spacing: .space16) {
                    if isInvitationAvailable {
                        choiceButton(
                            systemImage: "paperplane",
                            title: .localized("招待リンクを送る"),
                            description: .localized("離れていても、リンクから参加してもらえます"),
                            action: onTapInvite
                        )
                    }
                    choiceButton(
                        systemImage: "person.2",
                        title: .localized("パートナーが隣にいる"),
                        description: .localized("近くにいるパートナーと、その場で登録できます"),
                        action: onTapNearby
                    )
                    choiceButton(
                        systemImage: "envelope.open",
                        title: .localized("招待リンクを受け取った"),
                        description: .localized("届いた招待リンクから、パートナーのグループに参加できます"),
                        action: onTapInvited
                    )
                    if isInvitationNotFound {
                        invitationNotFoundNote
                    }
                }
                Button(.localized("あとで登録する")) {
                    onTapLater()
                }
                .font(with: .body)
                .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.backgroundScreen)
    }

}

// MARK: UI定義

private extension PartnerRegistrationView {

    var header: some View {
        VStack(spacing: .space16) {
            HometteView(.cheer, size: .medium)
            Text("誰と使いますか？", bundle: #bundle)
                .font(with: .headLineM)
            Text("パートナーを登録すると、家事を分け合えます", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var invitationNotFoundNote: some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.textPrimary)
            Text("招待リンクが見つかりませんでした。届いた招待リンクをもう一度開いてください", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius20)
                .fill(.backgroundCard)
        }
    }

    func choiceButton(
        systemImage: String,
        title: LocalizedStringResource,
        description: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: .space16) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.iconDecorative)
                    .frame(width: .space32)
                VStack(alignment: .leading, spacing: .space4) {
                    Text(title)
                        .font(with: .headLineS)
                        .foregroundStyle(.textPrimary)
                    Text(description)
                        .font(with: .caption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.textSecondary)
            }
            .multilineTextAlignment(.leading)
            .padding(.space16)
            .background {
                RoundedRectangle(radius: .radius20)
                    .fill(.backgroundCard)
            }
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    PartnerRegistrationView(
        isInvitationAvailable: true,
        isInvitationNotFound: false,
        onTapInvite: {},
        onTapNearby: {},
        onTapInvited: {},
        onTapLater: {}
    )
}

#Preview("PartnerRegistrationView_招待リンクが見つからない") {
    PartnerRegistrationView(
        isInvitationAvailable: true,
        isInvitationNotFound: true,
        onTapInvite: {},
        onTapNearby: {},
        onTapInvited: {},
        onTapLater: {}
    )
}

#Preview("PartnerRegistrationView_招待リンクを使えない") {
    PartnerRegistrationView(
        isInvitationAvailable: false,
        isInvitationNotFound: false,
        onTapInvite: {},
        onTapNearby: {},
        onTapInvited: {},
        onTapLater: {}
    )
}
