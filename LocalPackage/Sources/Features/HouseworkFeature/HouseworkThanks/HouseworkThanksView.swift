//
//  HouseworkThanksView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

public struct HouseworkThanksView: View {

    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @CommonError var commonError
    @LoadingState var loadingState

    @State var inputMessage: String

    let item: HouseworkBoardItem
    /// すでに送ったありがとう。あればコメントの編集として開く
    let sentThanks: HouseworkThanks?

    init(item: HouseworkBoardItem, sentThanks: HouseworkThanks? = nil) {
        self.item = item
        self.sentThanks = sentThanks
        _inputMessage = State(initialValue: sentThanks?.comment ?? "")
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .space40) {
                    VStack(spacing: .space24) {
                        if let executorId = item.executorId,
                           let executorUserName = cohabitantStore.members.userName(executorId) {
                            notificationSection(executorUserName)
                        }
                        houseworkPropertySection()
                        inputMessageSection()
                    }
                    actionButtonContent()
                }
                .padding(.horizontal, .space16)
                .padding(.bottom, .space24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(isEditing ? "メッセージを編集" : "ありがとうを伝える")
            .inlineNavigationBarTitleDisplayMode()
            .softTopScrollEdgeEffect()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    dismiss()
                }
            }
            .fullScreenLoadingIndicator(loadingState)
        }
        .trackScreenView(.houseworkThanks)
    }

}

private extension HouseworkThanksView {

    func notificationSection(_ executorName: String) -> some View {
        section {
            VStack(spacing: .zero) {
                Text("\(executorName)さんが")
                Text("「\(item.title)」を")
                Text("終えてくれました")
            }
            .font(with: .body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .space16)
        }
    }

    func houseworkPropertySection() -> some View {
        section {
            HouseworkItemPropertyListContent(item: item)
                .padding(.vertical, .space8)
        }
    }

    func inputMessageSection() -> some View {
        VStack(spacing: .space16) {
            Text("メッセージ")
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
            section {
                TextField("感謝を伝えましょう！", text: $inputMessage, axis: .vertical)
                    .font(with: .body)
                    .padding(.space16)
                    .frame(minHeight: 150, alignment: .topLeading)
                    .onChange(of: inputMessage) {
                        limitInputMessage()
                    }
            }
            Text("\(inputMessage.count)/\(HouseworkThanks.commentMaxLength)")
                .font(with: .caption)
                .foregroundStyle(.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func section(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(.subSurface)
            }
    }

    func actionButtonContent() -> some View {
        Button {
            loadingState.task {
                await tappedSendThanksButton()
            }
        } label: {
            Text(isEditing ? "メッセージを更新する" : "ありがとうを伝える")
                .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
        .disabled(!canSubmit)
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkThanksView {

    var isEditing: Bool {
        sentThanks != nil
    }

    /// 空のまま、または編集で内容を変えていないときは送れない
    var canSubmit: Bool {
        !inputMessage.isEmpty && inputMessage != sentThanks?.comment
    }

    /// コメントの上限を超えた入力を切り詰める
    func limitInputMessage() {
        guard inputMessage.count > HouseworkThanks.commentMaxLength else { return }
        inputMessage = String(inputMessage.prefix(HouseworkThanks.commentMaxLength))
    }

    func tappedSendThanksButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            try await houseworkListStore.sendThanks(
                target: item.originalItem,
                sender: account,
                comment: inputMessage,
                now: now,
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
    .environment(CohabitantStore(
        members: [.init(id: "test", userName: "hogehoge")],
        ownId: "test"
    ))
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
    )
    .setupEnvironmentForPreview()
    .environment(CohabitantStore(
        members: [.init(id: "test", userName: "hogehoge")],
        ownId: "test"
    ))
    .environment(HouseworkListStore())
}
#endif
