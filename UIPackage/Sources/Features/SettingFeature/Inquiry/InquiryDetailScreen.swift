//
//  InquiryDetailScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HometeDomain
import HometeUI
import SettingFeatureUI
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
