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
    @CommonError var commonError
    @LoadingState var loadingState

    @State var inputMessage = ""

    let item: HouseworkBoardItem

    public var body: some View {
        NavigationStack {
            ScrollView {
                HouseworkCommentInputContent(
                    title: "メッセージ",
                    placeholder: "感謝を伝えましょう！",
                    text: $inputMessage
                )
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("ありがとうを伝える")
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                sendThanksButton()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkThanks)
    }

}

private extension HouseworkThanksView {

    func sendThanksButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "heart.fill") {
            loadingState.task {
                await tappedSendThanksButton()
            }
        }
        .foregroundStyle(.onPrimary1)
        .disabled(inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkThanksView {

    func tappedSendThanksButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            try await houseworkListStore.sendThanks(
                target: item.originalItem,
                sender: account,
                comment: inputMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                cohabitantId: cohabitantId,
                step: .thanks
            )
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
    ))
    .setupEnvironmentForPreview()
    .environment(HouseworkListStore())
}
#endif
