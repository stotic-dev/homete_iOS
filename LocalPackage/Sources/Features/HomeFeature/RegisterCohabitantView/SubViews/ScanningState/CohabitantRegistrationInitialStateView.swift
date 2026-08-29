//
//  CohabitantRegistrationInitialStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import HometeResources
import HometeUI
import SwiftUI

struct CohabitantRegistrationInitialStateView: View {

    /// 招待リンクの共有アクション
    /// - Note: nilの場合は招待リンクの導線を表示しない
    let onTapInvite: (() -> Void)?

    init(onTapInvite: (() -> Void)? = nil) {
        self.onTapInvite = onTapInvite
    }

    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .space16) {
                Text("同居人の登録")
                    .font(with: .headLineL)
                Text("同居人同士でこの画面を開いて近づけてください。自動的に登録が始まります。")
                    .font(with: .body)
            }
            Spacer()
                .frame(height: .space24)
            Image(.cohabitantsRegistrationGuide)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius8)
            Spacer()
                .frame(height: .space16)
            if let onTapInvite {
                inviteSection(onTapInvite: onTapInvite)
            }
        }
        .padding(.horizontal, .space16)
    }

}

private extension CohabitantRegistrationInitialStateView {

    func inviteSection(onTapInvite: @escaping () -> Void) -> some View {
        VStack(spacing: .space8) {
            Text("離れている相手には、招待リンクを送って参加してもらえます。")
                .font(with: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onTapInvite()
            } label: {
                Label("リンクで招待", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }

}

#Preview {
    CohabitantRegistrationInitialStateView()
}

#Preview("CohabitantRegistrationInitialStateView_招待リンクあり") {
    CohabitantRegistrationInitialStateView {}
}
