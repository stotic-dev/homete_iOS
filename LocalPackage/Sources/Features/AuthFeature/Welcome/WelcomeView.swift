//
//  WelcomeView.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// ログイン前にアプリを紹介する説明画面のUI
///
/// 最後のページまで読まなくても始められるよう、「はじめる」「すでにアカウントをお持ちの方」はページの外に置く。
struct WelcomeView: View {

    @Binding var selectedPage: WelcomePage
    let invitation: WelcomeInvitation
    let onTapStart: () -> Void
    let onTapExistingAccount: () -> Void

    var body: some View {
        VStack(spacing: .space16) {
            TabView(selection: $selectedPage) {
                ForEach(WelcomePage.allCases, id: \.self) { page in
                    pageContent(page)
                        .tag(page)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            pageIndicator
            actions
        }
        .padding(.bottom, .space16)
        .background(.backgroundScreen)
    }

}

// MARK: UI定義

private extension WelcomeView {

    func pageContent(_ page: WelcomePage) -> some View {
        VStack(spacing: .space16) {
            if page == .record {
                invitationBanner
            }
            Spacer()
            WelcomeIllustration(page: page)
            pageTitle(page)
                .font(with: .headLineL)
                .multilineTextAlignment(.center)
            pageDescription(page)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, .space16)
    }

    @ViewBuilder
    var invitationBanner: some View {
        switch invitation {
        case .none:
            EmptyView()

        case let .invited(inviterName):
            Label {
                invitationMessage(inviterName: inviterName)
                    .font(with: .boldCaption)
                    .foregroundStyle(.textPrimary)
            } icon: {
                Image(systemName: "envelope.fill")
                    .font(with: .caption)
                    .foregroundStyle(.textAccent)
            }
            .padding(.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(radius: .radius12)
                    .fill(.fillAccentSubtle)
            }
            .padding(.top, .space16)
        }
    }

    @ViewBuilder
    func invitationMessage(inviterName: String?) -> some View {
        if let inviterName {
            Text("\(inviterName)さんから招待が届いています", bundle: #bundle)
        } else {
            Text("パートナーから招待が届いています", bundle: #bundle)
        }
    }

    /// 現在のページをアクセントカラーで塗り、ほかのページは薄く表示する
    /// - Note: 色の選び方は`OnboardingProgressIndicator`にそろえる
    var pageIndicator: some View {
        HStack(spacing: .space8) {
            ForEach(WelcomePage.allCases, id: \.self) { page in
                Circle()
                    .fill(page == selectedPage ? Color.fillAccent : Color.iconDecorative.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(.localized("全\(WelcomePage.allCases.count)ページ中\(currentPageNumber)ページ目"))
    }

    var currentPageNumber: Int {
        (WelcomePage.allCases.firstIndex(of: selectedPage) ?? 0) + 1
    }

    var actions: some View {
        VStack(spacing: .space16) {
            Button {
                onTapStart()
            } label: {
                Text("はじめる", bundle: #bundle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            Button {
                onTapExistingAccount()
            } label: {
                Text("すでにアカウントをお持ちの方", bundle: #bundle)
            }
            .font(with: .body)
            .tint(.textAccent)
            // swiftlint:disable line_length
            Text(
                "はじめると、[利用規約](https://stotic-dev.github.io/homete_iOS/terms.html)と[プライバシーポリシー](https://stotic-dev.github.io/homete_iOS/privacy.html)に同意したことになります。",
                bundle: #bundle
            )
            // swiftlint:enable line_length
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
            .tint(.textAccent)
        }
        .padding(.horizontal, .space16)
    }

    @ViewBuilder
    func pageTitle(_ page: WelcomePage) -> some View {
        switch page {
        case .record:
            Text("やった家事を、かんたんに記録できます", bundle: #bundle)
        case .share:
            Text("パートナーと家事を分け合えます", bundle: #bundle)
        case .thanks:
            Text("ありがとうを送り合えます", bundle: #bundle)
        }
    }

    @ViewBuilder
    func pageDescription(_ page: WelcomePage) -> some View {
        switch page {
        case .record:
            Text("終わった家事を記録すると、だれがどれだけがんばったか、あとから振り返れます", bundle: #bundle)
        case .share:
            Text("家事のリストを共有すると、だれがやるか、もう終わったかがひと目で分かります", bundle: #bundle)
        case .thanks:
            Text("パートナーが家事を終えると通知が届きます。ひとこと添えて、ありがとうを伝えられます", bundle: #bundle)
        }
    }

}

#Preview("WelcomeView_招待なし") {
    WelcomeView(
        selectedPage: .constant(.record),
        invitation: .none,
        onTapStart: {},
        onTapExistingAccount: {}
    )
}

#Preview("WelcomeView_招待あり") {
    WelcomeView(
        selectedPage: .constant(.record),
        invitation: .invited(inviterName: "たろう"),
        onTapStart: {},
        onTapExistingAccount: {}
    )
}

#Preview("WelcomeView_招待者名なし") {
    WelcomeView(
        selectedPage: .constant(.record),
        invitation: .invited(inviterName: nil),
        onTapStart: {},
        onTapExistingAccount: {}
    )
}

#Preview("WelcomeView_パートナーと共有") {
    WelcomeView(
        selectedPage: .constant(.share),
        invitation: .none,
        onTapStart: {},
        onTapExistingAccount: {}
    )
}

#Preview("WelcomeView_ありがとう") {
    WelcomeView(
        selectedPage: .constant(.thanks),
        invitation: .none,
        onTapStart: {},
        onTapExistingAccount: {}
    )
}
