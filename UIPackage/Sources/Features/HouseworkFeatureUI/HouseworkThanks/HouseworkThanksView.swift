//
//  HouseworkThanksView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import HometeModel
import HometeUI
import SwiftUI

/// 完了した家事にありがとうを伝えるハーフモーダルの中身
/// - Note: 送る処理は`HouseworkThanksScreen`が受け持つ。`NavigationStack`の中に置かれる前提でツールバーの項目を並べる
public struct HouseworkThanksView: View {

    @State var inputMessage: String
    @FocusState var isShowingKeyboard: Bool

    /// すでに送ったありがとう。あればコメントの編集として開く
    let sentThanks: HouseworkThanks?
    /// 前後の空白・改行を除いたメッセージで送る
    let onTapSend: (String) -> Void

    public init(
        sentThanks: HouseworkThanks? = nil,
        onTapSend: @escaping (String) -> Void
    ) {
        self.sentThanks = sentThanks
        self.onTapSend = onTapSend
        _inputMessage = State(initialValue: sentThanks?.comment ?? "")
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: .space8) {
                HouseworkCommentInputContent(
                    title: .localized("メッセージ"),
                    placeholder: .localized("ひとこと添えてみませんか（例：助かったよ）"),
                    text: $inputMessage,
                    focus: $isShowingKeyboard
                )
                commentLengthLabel()
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space24)
            .padding(.bottom, .space8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(navigationTitle)
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            sendThanksButton()
        }
        .onAppear {
            // メッセージを書いてもらうだけの画面なので、開いた直後からキーボードを出しておく
            isShowingKeyboard = true
        }
    }

}

private extension HouseworkThanksView {

    func commentLengthLabel() -> some View {
        Text("\(trimmedMessage.count)/\(HouseworkThanks.commentMaxLength)")
            .font(with: .caption)
            .foregroundStyle(isOverCommentLimit ? .textDestructive : .textSecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    func sendThanksButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "heart.fill") {
            onTapSend(trimmedMessage)
        }
        .foregroundStyle(.textOnAccent)
        .accessibilityLabel(submitButtonLabel)
        .disabled(!canSubmit)
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkThanksView {

    /// すでに送ったメッセージを直すかどうか
    ///
    /// コメントなしで送ったありがとうに書き足す場合は、まだメッセージを送っていないので編集として扱わない。
    var isEditingMessage: Bool {
        sentThanks?.comment != nil
    }

    var navigationTitle: LocalizedStringResource {
        if isEditingMessage {
            .localized("メッセージを編集")
        } else if sentThanks != nil {
            .localized("メッセージを添える")
        } else {
            .localized("ありがとうを伝える")
        }
    }

    var submitButtonLabel: LocalizedStringResource {
        if isEditingMessage {
            .localized("メッセージを更新する")
        } else if sentThanks != nil {
            .localized("メッセージを送る")
        } else {
            .localized("ありがとうを伝える")
        }
    }

    /// 前後の空白・改行を除いた、送るメッセージ
    var trimmedMessage: String {
        inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// コメントが上限の文字数を超えているか
    ///
    /// 入力中に切り詰めると、日本語の変換中の文字まで消えてしまうため、超えた入力も受け付けた上で送れなくする。
    var isOverCommentLimit: Bool {
        trimmedMessage.count > HouseworkThanks.commentMaxLength
    }

    /// 空のまま・上限を超えている・編集で内容を変えていないときは送れない
    var canSubmit: Bool {
        !trimmedMessage.isEmpty && !isOverCommentLimit && trimmedMessage != sentThanks?.comment
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        HouseworkThanksView { _ in }
    }
    .setupEnvironmentForPreview()
}

#Preview("HouseworkThanksView_メッセージを添える") {
    NavigationStack {
        HouseworkThanksView(sentThanks: .init(comment: nil, sentAt: .distantFuture)) { _ in }
    }
    .setupEnvironmentForPreview()
}

#Preview("HouseworkThanksView_編集") {
    NavigationStack {
        HouseworkThanksView(sentThanks: .init(comment: "いつもありがとう！", sentAt: .distantFuture)) { _ in }
    }
    .setupEnvironmentForPreview()
}
#endif
