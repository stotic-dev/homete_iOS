//
//  InquiryCreationScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
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

/// 問い合わせの作成画面の中身
struct InquiryCreationView: View {

    @Binding var category: InquiryCategory?
    @Binding var bodyText: String
    @FocusState var isFocusedBody: Bool

    let bodyValidation: InquiryMessageBody
    let canSubmit: Bool
    let isSending: Bool
    let onTapClose: () -> Void
    let onTapSubmit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                categorySection()
                bodySection()
                Text("送信すると、アプリとOSのバージョン、端末の機種もあわせて運営に届きます。返信は、お問い合わせの一覧から確認できます。", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, .space16)
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.backgroundScreen)
        .navigationTitle(.localized("お問い合わせ"))
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
            .disabled(isSending)
        }
        .trailingToolbarItem {
            if isSending {
                ProgressView()
            } else {
                NavigationBarPrimaryActionButton(systemImage: "paperplane.fill") {
                    onTapSubmit()
                }
                .foregroundStyle(.textOnAccent)
                .disabled(!canSubmit)
                .accessibilityLabel(Text("送信", bundle: #bundle))
            }
        }
    }

}

// MARK: - UI定義

private extension InquiryCreationView {

    func categorySection() -> some View {
        SectionCard(.localized("どんなことについてですか")) {
            ForEach(Array(InquiryCategory.allCases.enumerated()), id: \.element) { index, item in
                Button {
                    category = item
                } label: {
                    HStack(spacing: .space8) {
                        Text(InquiryDisplayText.category(item))
                            .font(with: .body)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        if category == item {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.textAccent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(category == item ? .isSelected : [])
                if index < InquiryCategory.allCases.count - 1 {
                    Divider()
                }
            }
        }
    }

    func bodySection() -> some View {
        SectionCard(.localized("内容")) {
            ZStack(alignment: .topLeading) {
                if bodyText.isEmpty {
                    Text("困っていることや、そのときの操作をできるだけ詳しく書いてください", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
                        // TextEditorの文字の位置にそろえる
                        .padding(.top, .space8)
                        .padding(.leading, .space4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $bodyText)
                    .font(with: .body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .focused($isFocusedBody)
            }
            InquiryBodyLengthLabel(length: bodyText.count, isTooLong: bodyValidation == .tooLong)
        } onTapBackground: {
            isFocusedBody = true
        }
    }

}

// MARK: - Preview定義

#Preview("InquiryCreationView_未入力") {
    NavigationStack {
        InquiryCreationView(
            category: .constant(nil),
            bodyText: .constant(""),
            bodyValidation: .empty,
            canSubmit: false,
            isSending: false,
            onTapClose: {},
            onTapSubmit: {}
        )
    }
}

#Preview("InquiryCreationView_入力済み") {
    NavigationStack {
        InquiryCreationView(
            category: .constant(.bug),
            bodyText: .constant("家事を完了にしても、ボードに反映されないことがあります。"),
            bodyValidation: .valid,
            canSubmit: true,
            isSending: false,
            onTapClose: {},
            onTapSubmit: {}
        )
    }
}

#Preview("InquiryCreationView_文字数超過") {
    NavigationStack {
        InquiryCreationView(
            category: .constant(.feature),
            bodyText: .constant(String(repeating: "あ", count: 2001)),
            bodyValidation: .tooLong,
            canSubmit: false,
            isSending: false,
            onTapClose: {},
            onTapSubmit: {}
        )
    }
}
