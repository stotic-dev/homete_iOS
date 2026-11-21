//
//  InquiryCreationView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 問い合わせの作成画面の中身
public struct InquiryCreationView: View {

    @Binding var category: InquiryCategory?
    @Binding var bodyText: String
    @FocusState var isFocusedBody: Bool

    let bodyValidation: InquiryMessageBody
    let canSubmit: Bool
    let isSending: Bool
    let onTapClose: () -> Void
    let onTapSubmit: () -> Void

    public init(
        category: Binding<InquiryCategory?>,
        bodyText: Binding<String>,
        bodyValidation: InquiryMessageBody,
        canSubmit: Bool,
        isSending: Bool,
        onTapClose: @escaping () -> Void,
        onTapSubmit: @escaping () -> Void
    ) {
        _category = category
        _bodyText = bodyText
        self.bodyValidation = bodyValidation
        self.canSubmit = canSubmit
        self.isSending = isSending
        self.onTapClose = onTapClose
        self.onTapSubmit = onTapSubmit
    }

    public var body: some View {
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
            // 選択肢を常に並べると場所をとるので、タップしたときだけメニューで出す
            Menu {
                Picker(selection: $category) {
                    ForEach(InquiryCategory.allCases, id: \.self) { item in
                        Text(InquiryDisplayText.category(item))
                            .tag(Optional(item))
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: .space8) {
                    categoryLabel()
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(with: .caption)
                        .foregroundStyle(.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func categoryLabel() -> some View {
        if let category {
            Text(InquiryDisplayText.category(category))
                .font(with: .body)
                .foregroundStyle(.textPrimary)
        } else {
            Text("選択してください", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
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
