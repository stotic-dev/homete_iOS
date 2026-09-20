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
/// 内容の読み取りはシステムのペースト通知が出るため、ユーザーのタップ起点でのみ行う。
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
                    .foregroundStyle(.primary3)
                VStack(alignment: .leading, spacing: .space4) {
                    Text("招待リンクをコピーしましたか？")
                        .font(with: .headLineS)
                        .foregroundStyle(.onSurface)
                    Text("コピーした招待リンクから、そのままグループに参加できます。")
                        .font(with: .caption)
                        .foregroundStyle(.onSubSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                onTapCheck()
            } label: {
                Text("招待リンクを確認する")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius16)
                .fill(.subSurface)
        }
    }

    func notFoundContent() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.onSubSurface)
            Text("コピーした内容に招待リンクが見つかりませんでした。招待した方にリンクを送ってもらい、もう一度タップしてください。")
                .font(with: .caption)
                .foregroundStyle(.onSubSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius16)
                .fill(.subSurface)
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
