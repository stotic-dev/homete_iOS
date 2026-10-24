//
//  InquiryMessageInputBar.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせの詳細画面の下に置く、追加のメッセージの入力欄と送信ボタン
struct InquiryMessageInputBar: View {

    @Binding var messageText: String

    let bodyValidation: InquiryMessageBody
    let canSubmit: Bool
    let isSending: Bool
    let onTapSubmit: () -> Void

    var body: some View {
        VStack(spacing: .space4) {
            HStack(alignment: .bottom, spacing: .space8) {
                TextField(text: $messageText, axis: .vertical) {
                    Text("メッセージを入力", bundle: #bundle)
                }
                .font(with: .body)
                .lineLimit(1 ... 5)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space8)
                .background(.backgroundScreen, in: RoundedRectangle(radius: .radius20))
                submitButton()
            }
            // 上限に近づくまでは文字数を出さず、入力欄を広く使う
            if messageText.count > InquiryMessageBody.maxLength - 200 {
                InquiryBodyLengthLabel(length: messageText.count, isTooLong: bodyValidation == .tooLong)
            }
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .background(.backgroundCard)
    }

}

// MARK: - UI定義

private extension InquiryMessageInputBar {

    @ViewBuilder
    func submitButton() -> some View {
        if isSending {
            ProgressView()
                .frame(width: 36, height: 36)
        } else {
            Button {
                onTapSubmit()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.fillAccent)
            }
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.4)
            .accessibilityLabel(Text("送信", bundle: #bundle))
        }
    }

}

// MARK: - Preview定義

#Preview("InquiryMessageInputBar_未入力", traits: .sizeThatFitsLayout) {
    InquiryMessageInputBar(
        messageText: .constant(""),
        bodyValidation: .empty,
        canSubmit: false,
        isSending: false,
        onTapSubmit: {}
    )
}

#Preview("InquiryMessageInputBar_送信中", traits: .sizeThatFitsLayout) {
    InquiryMessageInputBar(
        messageText: .constant("再起動しても同じでした。"),
        bodyValidation: .valid,
        canSubmit: false,
        isSending: true,
        onTapSubmit: {}
    )
}

#Preview("InquiryMessageInputBar_文字数超過", traits: .sizeThatFitsLayout) {
    InquiryMessageInputBar(
        messageText: .constant(String(repeating: "あ", count: 2001)),
        bodyValidation: .tooLong,
        canSubmit: false,
        isSending: false,
        onTapSubmit: {}
    )
}
