//
//  NotRegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct NotRegisteredContent: View {

    @Binding var isShowCohabitantRegistrationModal: Bool
    /// クリップボードにコピーされた招待リンクの案内状態
    let pasteboardInvitationState: PasteboardInvitationStore.State
    /// 「招待リンクを確認する」タップ時の処理
    let onTapCheckPasteboard: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: .space24)
            VStack(spacing: .space24) {
                Image(.suggest_partner)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(.radius16)
                VStack(spacing: .space8) {
                    Text("まだパートナーが登録されていません")
                        .font(with: .headLineS)
                    Text("パートナーを登録して、家事を分担しましょう！")
                        .font(with: .body)
                }
                Button("パートナーを登録する") {
                    isShowCohabitantRegistrationModal = true
                }
                .primaryButtonStyle()
                PasteboardInvitationBanner(state: pasteboardInvitationState, onTapCheck: onTapCheckPasteboard)
                Spacer()
            }
        }
        .padding(.horizontal, .space16)
        .trackScreenView(.dashboardNotRegistered)
    }

}

#Preview {
    @Previewable @State var isShowCohabitantRegistrationModal = false
    NotRegisteredContent(
        isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal,
        pasteboardInvitationState: .idle,
        onTapCheckPasteboard: {}
    )
}

#Preview("NotRegisteredContent_招待リンクの案内あり") {
    @Previewable @State var isShowCohabitantRegistrationModal = false
    NotRegisteredContent(
        isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal,
        pasteboardInvitationState: .suggesting,
        onTapCheckPasteboard: {}
    )
}
