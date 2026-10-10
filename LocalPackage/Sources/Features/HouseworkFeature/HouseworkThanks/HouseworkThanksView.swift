//
//  HouseworkThanksView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 完了した家事にありがとうを伝えるハーフモーダル
public struct HouseworkThanksView: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @CommonError var commonError
    @LoadingState var loadingState

    @State var inputMessage: String
    @FocusState var isShowingKeyboard: Bool

    let item: HouseworkBoardItem
    /// すでに送ったありがとう。あればコメントの編集として開く
    let sentThanks: HouseworkThanks?
    /// 初めてありがとうを伝えられた。閉じた後の画面で演出を出すために、開いた側へ伝える
    let onSentFirstThanks: () -> Void

    init(item: HouseworkBoardItem, sentThanks: HouseworkThanks? = nil, onSentFirstThanks: @escaping () -> Void) {
        self.item = item
        self.sentThanks = sentThanks
        self.onSentFirstThanks = onSentFirstThanks
        _inputMessage = State(initialValue: sentThanks?.comment ?? "")
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .space8) {
                    HouseworkCommentInputContent(
                        title: .localized("メッセージ"),
                        placeholder: .localized("感謝を伝えましょう！"),
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
        }
        // 中身の高さに合わせると、キーボードを出したときにシートが持ち上がりすぎてハーフモーダルに
        // ならないため、高さを決め打ちする
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkThanks)
        .onAppear {
            // メッセージを書いてもらうだけの画面なので、開いた直後からキーボードを出しておく
            isShowingKeyboard = true
        }
    }

}

private extension HouseworkThanksView {

    /// ハーフモーダルの高さ。3行の入力欄と文字数が収まる高さ
    var sheetHeight: CGFloat {
        250
    }

    func commentLengthLabel() -> some View {
        Text("\(trimmedMessage.count)/\(HouseworkThanks.commentMaxLength)")
            .font(with: .caption)
            .foregroundStyle(isOverCommentLimit ? .textDestructive : .textSecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    func sendThanksButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "heart.fill") {
            loadingState.task {
                await tappedSendThanksButton()
            }
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

    func tappedSendThanksButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let isFirstThanks = try await houseworkListStore.sendThanks(
                target: item.originalItem,
                sender: account,
                comment: trimmedMessage,
                now: now,
                cohabitantId: cohabitantId,
                step: .thanks
            )
            if isFirstThanks {
                onSentFirstThanks()
            }
            dismiss()
        } catch {
            commonError = .init(error: error)
        }
    }

}

#if DEBUG
#Preview {
    HouseworkThanksView(item: .makeForPreview(
        title: "洗濯",
        point: 10,
        indexedDate: .init(value: .previewDate(year: 1970, month: 1, day: 1)),
        state: .completed,
        executorId: "test",
        executedAt: .distantFuture
    )) {}
        .setupEnvironmentForPreview()
        .environment(HouseworkListStore())
}

#Preview("HouseworkThanksView_メッセージを添える") {
    HouseworkThanksView(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 1970, month: 1, day: 1)),
            state: .completed,
            executorId: "test",
            executedAt: .distantFuture
        ),
        sentThanks: .init(comment: nil, sentAt: .distantFuture)
    ) {}
        .setupEnvironmentForPreview()
        .environment(HouseworkListStore())
}

#Preview("HouseworkThanksView_編集") {
    HouseworkThanksView(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 1970, month: 1, day: 1)),
            state: .completed,
            executorId: "test",
            executedAt: .distantFuture
        ),
        sentThanks: .init(comment: "いつもありがとう！", sentAt: .distantFuture)
    ) {}
        .setupEnvironmentForPreview()
        .environment(HouseworkListStore())
}
#endif
