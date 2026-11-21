//
//  InquiryListView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 問い合わせの一覧画面の中身
public struct InquiryListView: View {

    let state: InquiryListState
    let onTapCreate: () -> Void
    let onTapInquiry: (Inquiry) -> Void
    /// 一覧の末尾まで表示したときに呼ぶ。次のページを読み込むのに使う
    let onReachEnd: () -> Void
    let onRefresh: () async -> Void
    let onTapRetry: () -> Void

    public init(
        state: InquiryListState,
        onTapCreate: @escaping () -> Void,
        onTapInquiry: @escaping (Inquiry) -> Void,
        onReachEnd: @escaping () -> Void,
        onRefresh: @escaping () async -> Void,
        onTapRetry: @escaping () -> Void
    ) {
        self.state = state
        self.onTapCreate = onTapCreate
        self.onTapInquiry = onTapInquiry
        self.onReachEnd = onReachEnd
        self.onRefresh = onRefresh
        self.onTapRetry = onTapRetry
    }

    public var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.backgroundScreen)
            .navigationTitle(.localized("お問い合わせ"))
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                NavigationBarPrimaryActionButton(systemImage: "square.and.pencil") {
                    onTapCreate()
                }
                .foregroundStyle(.textOnAccent)
                .accessibilityLabel(Text("新しく問い合わせる", bundle: #bundle))
            }
    }

}

// MARK: - UI定義

private extension InquiryListView {

    @ViewBuilder
    func content() -> some View {
        if !state.inquiries.isEmpty {
            inquiryList()
        } else if state.hasLoaded {
            emptyContent()
        } else if let failure = state.loadFailure {
            LoadErrorView(error: failure, onTapRetry: onTapRetry)
        } else {
            ProgressView()
        }
    }

    func inquiryList() -> some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(Array(state.inquiries.enumerated()), id: \.element.id) { index, inquiry in
                    Button {
                        onTapInquiry(inquiry)
                    } label: {
                        InquiryListRow(inquiry: inquiry)
                    }
                    .buttonStyle(.plain)
                    if index < state.inquiries.count - 1 {
                        Divider()
                    }
                }
                if state.hasMore {
                    ProgressView()
                        .padding(.vertical, .space16)
                        .onAppear {
                            onReachEnd()
                        }
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
            .padding(.space16)
        }
        .refreshable {
            await onRefresh()
        }
    }

    func emptyContent() -> some View {
        ScrollView {
            VStack(spacing: .space24) {
                VStack(spacing: .space16) {
                    HometteView(.normal)
                    Text("お問い合わせはまだありません", bundle: #bundle)
                        .font(with: .headLineM)
                        .multilineTextAlignment(.center)
                    Text("不具合やご要望、使い方で困ったことがあれば、こちらから運営に送れます。返信もこの画面で確認できます。", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button {
                    onTapCreate()
                } label: {
                    Text("問い合わせる", bundle: #bundle)
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space40)
        }
        .refreshable {
            await onRefresh()
        }
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("InquiryListView_一覧") {
    NavigationStack {
        InquiryListView(
            state: .init(
                inquiries: [
                    .preview(
                        id: "1",
                        category: .usage,
                        status: .inProgress,
                        lastMessageSender: .admin,
                        hasUnreadReply: true,
                        messageCount: 2
                    ),
                    .preview(id: "2"),
                    .preview(
                        id: "3",
                        category: .account,
                        status: .resolved,
                        lastMessageSender: .admin,
                        messageCount: 3
                    ),
                ],
                unreadCount: 1,
                hasLoaded: true
            ),
            onTapCreate: {},
            onTapInquiry: { _ in },
            onReachEnd: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("InquiryListView_空") {
    NavigationStack {
        InquiryListView(
            state: .init(hasLoaded: true),
            onTapCreate: {},
            onTapInquiry: { _ in },
            onReachEnd: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
}

#Preview("InquiryListView_取得失敗") {
    NavigationStack {
        InquiryListView(
            state: .init(loadFailure: .noNetwork),
            onTapCreate: {},
            onTapInquiry: { _ in },
            onReachEnd: {},
            onRefresh: {},
            onTapRetry: {}
        )
    }
}
#endif
