//
//  NotRegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeDomain
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
                HometteView(.cheer, size: .large)
                VStack(spacing: .space8) {
                    Text("まだパートナーが登録されていません", bundle: #bundle)
                        .font(with: .headLineS)
                    Text("パートナーを招待すると、家事を分け合えます", bundle: #bundle)
                        .font(with: .body)
                }
                Button(.localized("パートナーを登録する")) {
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
