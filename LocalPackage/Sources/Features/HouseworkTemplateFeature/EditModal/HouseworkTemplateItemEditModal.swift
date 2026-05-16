//
//  HouseworkTemplateItemEditModal.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事追加・編集モーダル（ハーフモーダル / 新規・編集兼用）。
struct HouseworkTemplateItemEditModal: View {

    @Environment(\.dismiss) var dismiss

    @State var input: TemplateItemEditInput = .initial(UUID())
    @FocusState var isShowingKeyboard: Bool

    let mode: EditMode
    let onConfirm: (TemplateItemEditInput) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .space16) {
                inputTitleField()
                inputPointSlider()
                inputDaysSelector()
                Spacer()
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space24)
            .padding(.bottom, .space24)
            .background {
                if isShowingKeyboard {
                    Color.clear
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isShowingKeyboard = false
                        }
                }
            }
            .navigationTitle(navigationTitle)
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    dismiss()
                }
            }
            .trailingToolbarItem {
                trailingNavigationItem()
            }
        }
        .presentationDetents([.medium, .large])
    }

}

// MARK: - UI定義

private extension HouseworkTemplateItemEditModal {

    var navigationTitle: String {
        switch mode {
        case .create: "家事を追加"
        case .edit: "家事を編集"
        }
    }

    func inputTitleField() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事の名前")
                .font(with: .headLineS)
            ZStack {
                TextField(
                    "",
                    text: $input.title,
                    prompt: Text("家事の名前を入力")
                        .foregroundStyle(.primary2.opacity(0.7))
                )
                .focused($isShowingKeyboard)
                .foregroundStyle(.primary2)
                .padding()
                .font(with: .body)
                .background {
                    RoundedRectangle(radius: .radius8)
                        .foregroundStyle(.primary3)
                }
                Button {
                    input.title = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.primary2)
                        .padding(.space8)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, .space8)
                .opacity(input.isEmptyTitle ? 0 : 1)
            }
        }
    }

    func inputPointSlider() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("ポイント")
                .font(with: .headLineS)
            HStack(spacing: .space16) {
                Slider(value: $input.point, in: 1 ... 100, step: 1)
                Text(Int(input.point).formatted())
                    .font(with: .headLineM)
                    .frame(minWidth: 40, alignment: .trailing)
            }
        }
    }

    func inputDaysSelector() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("曜日")
                .font(with: .headLineS)
            WeekdaySelector(selection: $input.days)
        }
    }

    func trailingNavigationItem() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "paperplane") {
            tappedConfirmButton()
        }
        .foregroundStyle(.onPrimary1)
        .disabled(!input.canConfirm)
    }

}

private extension HouseworkTemplateItemEditModal {

    func tappedConfirmButton() {
        onConfirm(input)
        dismiss()
    }

}

#if DEBUG
    #Preview("HouseworkTemplateItemEditModal_未入力") {
        HouseworkTemplateItemEditModal(mode: .create) { _ in }
    }

    #Preview("HouseworkTemplateItemEditModal_入力済み") {
        HouseworkTemplateItemEditModal(
            input: .init(
                itemId: .init(id: "1"),
                title: "hoge",
                point: 10,
                days: [.monday, .friday]
            ),
            mode: .create
        ) { _ in }
    }
#endif
