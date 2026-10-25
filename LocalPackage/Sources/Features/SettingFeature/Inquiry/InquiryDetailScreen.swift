//
//  InquiryDetailScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせの詳細画面（メッセージ履歴と追加の送信）
///
/// 運営の返信を表示したら既読にし、送信・既読の結果は一覧の`InquiryListStore`にも反映する。
struct InquiryDetailScreen: View {

    @Environment(\.scenePhase) var scenePhase
    @Environment(\.appDependencies.inquiryClient) var inquiryClient
    @Environment(InquiryListStore.self) var inquiryListStore

    @State var store: InquiryDetailStore?

    let inquiryId: String

    var body: some View {
        InquiryDetailView(
            state: store?.state ?? .init(),
            messageText: messageText,
            bodyValidation: store?.submission.bodyValidation ?? .empty,
            canSubmit: store?.submission.canSubmit ?? false,
            isSending: store?.submission.isSending ?? false,
            onTapLoadOlder: { loadOlder() },
            onTapSubmit: { submit() },
            onRefresh: { await store?.load() },
            onTapRetry: { reload() }
        )
        .task {
            await setupStoreAndLoad()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // 開いている間に届いた返信を、アプリに戻ったときに表示して既読にする
            guard newPhase == .active else { return }
            reload()
        }
        .alert(
            Text("送信できませんでした", bundle: #bundle),
            isPresented: isPresentedFailure,
            presenting: store?.submission.failure
        ) { _ in
            Button(.localized("OK")) {}
        } message: { failure in
            Text(InquiryDisplayText.submitFailureMessage(failure, context: .message))
        }
        .trackScreenView(.inquiryDetail)
    }

}

// MARK: - 表示内容

private extension InquiryDetailScreen {

    var messageText: Binding<String> {
        .init {
            store?.submission.body ?? ""
        } set: { newValue in
            store?.submission.body = newValue
        }
    }

    var isPresentedFailure: Binding<Bool> {
        .init {
            store?.submission.failure != nil
        } set: { isPresented in
            if !isPresented {
                store?.submission.failure = nil
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension InquiryDetailScreen {

    func setupStoreAndLoad() async {
        if store == nil {
            store = .init(
                inquiryId: inquiryId,
                inquiryClient: inquiryClient,
                onUpdate: { [inquiryListStore] inquiry in
                    inquiryListStore.apply(inquiry)
                }
            )
        }
        await store?.load()
    }

    func reload() {
        Task {
            await store?.load()
        }
    }

    func loadOlder() {
        Task {
            await store?.loadOlder()
        }
    }

    func submit() {
        Task {
            await store?.submit()
        }
    }

}

/// 問い合わせの詳細画面の中身
struct InquiryDetailView: View {

    @Environment(\.locale) var locale
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone

    let state: InquiryDetailState
    @Binding var messageText: String
    let bodyValidation: InquiryMessageBody
    let canSubmit: Bool
    let isSending: Bool
    let onTapLoadOlder: () -> Void
    let onTapSubmit: () -> Void
    let onRefresh: () async -> Void
    let onTapRetry: () -> Void

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.backgroundScreen)
            .navigationTitle(.localized("お問い合わせ"))
            .inlineNavigationBarTitleDisplayMode()
    }

}

// MARK: - UI定義

private extension InquiryDetailView {

    @ViewBuilder
    func content() -> some View {
        if let inquiry = state.inquiry {
            messageList(inquiry: inquiry)
                .safeAreaInset(edge: .bottom, spacing: .zero) {
                    InquiryMessageInputBar(
                        messageText: $messageText,
                        bodyValidation: bodyValidation,
                        canSubmit: canSubmit,
                        isSending: isSending,
                        onTapSubmit: onTapSubmit
                    )
                }
        } else if state.loadFailure == .notFound {
            notFoundContent()
        } else if case let .domain(error) = state.loadFailure {
            LoadErrorView(error: error, onTapRetry: onTapRetry)
        } else if state.loadFailure != nil {
            LoadErrorView(error: .other, onTapRetry: onTapRetry)
        } else {
            ProgressView()
        }
    }

    func messageList(inquiry: Inquiry) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: .space16) {
                    header(inquiry: inquiry)
                    if state.hasOlderMessages {
                        loadOlderButton()
                    }
                    ForEach(state.messages) { message in
                        InquiryMessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.space16)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await onRefresh()
            }
            .onChange(of: state.messages.last?.id) { _, lastMessageId in
                // 送った・届いたメッセージが見えるよう、最新のメッセージまで送る
                guard let lastMessageId else { return }
                withAnimation {
                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
        }
    }

    func header(inquiry: Inquiry) -> some View {
        VStack(spacing: .space8) {
            HStack(spacing: .space8) {
                Text(InquiryDisplayText.category(inquiry.category))
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                InquiryStatusLabel(status: inquiry.status)
            }
            Text("受付日時: \(inquiry.createdAt.formatted(dateFormat))", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, .space8)
    }

    @ViewBuilder
    func loadOlderButton() -> some View {
        if state.isLoadingOlder {
            ProgressView()
        } else {
            Button {
                onTapLoadOlder()
            } label: {
                Text("以前のメッセージを表示", bundle: #bundle)
                    .font(with: .boldCaption)
                    .foregroundStyle(.textAccent)
            }
        }
    }

    func notFoundContent() -> some View {
        VStack(spacing: .space16) {
            HometteView(.puzzled)
            Text("このお問い合わせは見つかりませんでした", bundle: #bundle)
                .font(with: .headLineM)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .space16)
    }

    var dateFormat: Date.FormatStyle {
        .init(date: .abbreviated, time: .shortened, locale: locale, calendar: calendar, timeZone: timeZone)
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("InquiryDetailView_返信あり") {
    NavigationStack {
        InquiryDetailView(
            state: .init(
                inquiry: .preview(status: .inProgress, lastMessageSender: .admin, messageCount: 2),
                messages: [.previewUser, .previewAdmin]
            ),
            messageText: .constant(""),
            bodyValidation: .empty,
            canSubmit: false,
            isSending: false,
            onTapLoadOlder: {},
            onTapSubmit: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("InquiryDetailView_以前のメッセージあり_入力中") {
    NavigationStack {
        InquiryDetailView(
            state: .init(
                inquiry: .preview(status: .resolved, lastMessageSender: .admin, messageCount: 30),
                messages: [.previewUser, .previewAdmin],
                olderCursor: "cursor"
            ),
            messageText: .constant("再起動しても同じでした。"),
            bodyValidation: .valid,
            canSubmit: true,
            isSending: false,
            onTapLoadOlder: {},
            onTapSubmit: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("InquiryDetailView_見つからない") {
    NavigationStack {
        InquiryDetailView(
            state: .init(loadFailure: .notFound),
            messageText: .constant(""),
            bodyValidation: .empty,
            canSubmit: false,
            isSending: false,
            onTapLoadOlder: {},
            onTapSubmit: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
}
#endif
