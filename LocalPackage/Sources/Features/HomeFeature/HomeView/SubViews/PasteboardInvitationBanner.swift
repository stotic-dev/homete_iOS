//
//  PasteboardInvitationBanner.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// クリップボードにコピーされた招待リンクの確認を促すバナー
///
/// 着地ページの「初めての方はこちら」で招待URLをコピーしてから App Store へ遷移したユーザーが、
/// インストール後にそのリンクから参加できるようにする（ディファードディープリンク）。
/// コピーは着地ページが自動で行うためユーザーはコピーした自覚がない。文言は「招待リンクから来たか」で問いかけ、
/// 「コピー」には触れない。内容の読み取りはシステムのペースト許可ダイアログが出るため、ユーザーのタップ起点でのみ行う。
struct PasteboardInvitationBanner: View {

    let state: PasteboardInvitationStore.State
    let onTapCheck: () -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .suggesting:
            suggestingContent()

        case .notFound:
            notFoundContent()
        }
    }

}

private extension PasteboardInvitationBanner {

    func suggestingContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(alignment: .top, spacing: .space8) {
                Image(systemName: "link")
                    .foregroundStyle(.iconDecorative)
                VStack(alignment: .leading, spacing: .space4) {
                    Text("招待リンクからアプリを開きましたか？", bundle: #bundle)
                        .font(with: .headLineS)
                        .foregroundStyle(.textPrimary)
                    Text("招待の内容を確認して、そのままグループに参加できます。", bundle: #bundle)
                        .font(with: .caption)
                        .foregroundStyle(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                onTapCheck()
            } label: {
                Text("招待リンクを確認する", bundle: #bundle)
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius20)
                .fill(.backgroundCard)
        }
    }

    func notFoundContent() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.textPrimary)
            Text("招待リンクが見つかりませんでした。招待した方から送ってもらったリンクをもう一度開くと、グループに参加できます。", bundle: #bundle)
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

}

#Preview("PasteboardInvitationBanner_案内", traits: .sizeThatFitsLayout) {
    PasteboardInvitationBanner(state: .suggesting, onTapCheck: {})
        .padding()
}

#Preview("PasteboardInvitationBanner_見つからない", traits: .sizeThatFitsLayout) {
    PasteboardInvitationBanner(state: .notFound, onTapCheck: {})
        .padding()
}
