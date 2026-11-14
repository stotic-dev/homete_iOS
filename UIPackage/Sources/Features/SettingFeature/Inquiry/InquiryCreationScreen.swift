//
//  InquiryCreationScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HometeDomain
import HometeUI
import SettingFeatureUI
import SwiftUI

/// 問い合わせの作成画面（シート）
struct InquiryCreationScreen: View {

    @Environment(\.dismiss) var dismiss

    @State var store: InquiryCreationStore
    @State var isPresentedDiscardConfirm = false

    let onCreate: (Inquiry) -> Void

    /// - Parameter onCreate: 作った問い合わせを受け取る。シートは閉じてから呼ぶ
    static func make(onCreate: @escaping (Inquiry) -> Void) -> some View {
        DependenciesInjectLayer {
            InquiryCreationScreen(store: .init(inquiryClient: $0.inquiryClient), onCreate: onCreate)
        }
    }

    init(store: InquiryCreationStore, onCreate: @escaping (Inquiry) -> Void) {
        _store = State(initialValue: store)
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationStack {
            InquiryCreationView(
                category: $store.category,
                bodyText: $store.submission.body,
                bodyValidation: store.submission.bodyValidation,
                canSubmit: store.canSubmit,
                isSending: store.submission.isSending,
                onTapClose: { tappedCloseButton() },
                onTapSubmit: { tappedSubmitButton() }
            )
        }
        // 入力の途中でシートを下げて、書いた内容を失わないようにする
        .interactiveDismissDisabled(store.hasInput || store.submission.isSending)
        .confirmationDialog(
            Text("入力した内容を破棄しますか？", bundle: #bundle),
            isPresented: $isPresentedDiscardConfirm,
            titleVisibility: .visible
        ) {
            Button(.localized("破棄する"), role: .destructive) {
                dismiss()
            }
        }
        .alert(
            Text("送信できませんでした", bundle: #bundle),
            isPresented: isPresentedFailure,
            presenting: store.submission.failure
        ) { _ in
            Button(.localized("OK")) {}
        } message: { failure in
            Text(InquiryDisplayText.submitFailureMessage(failure, context: .creation))
        }
        .trackScreenView(.inquiryCreation)
    }

}

// MARK: - 表示内容

private extension InquiryCreationScreen {

    var isPresentedFailure: Binding<Bool> {
        .init {
            store.submission.failure != nil
        } set: { isPresented in
            if !isPresented {
                store.submission.failure = nil
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension InquiryCreationScreen {

    func tappedCloseButton() {
        if store.hasInput {
            isPresentedDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    func tappedSubmitButton() {
        Task {
            guard let inquiry = await store.submit() else { return }
            dismiss()
            onCreate(inquiry)
        }
    }

}
