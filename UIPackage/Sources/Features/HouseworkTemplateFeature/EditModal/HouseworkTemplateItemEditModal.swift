//
//  HouseworkTemplateItemEditModal.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomainUI
import HometeDomain
import HometeUI
import HouseworkTemplateFeatureUI
import SwiftUI

/// 家事追加・編集モーダル（ハーフモーダル / 新規・編集兼用）
struct HouseworkTemplateItemEditModalScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.routeResolver) var router
    @Environment(SubscriptionStore.self) var subscriptionStore

    @State var isPresentedMemoEditSheet = false
    @State var input: TemplateItemEditInput = .initial(UUID())
    @FocusState var isShowingKeyboard: Bool

    let mode: HouseworkTemplateEditMode
    let onConfirm: (TemplateItemEditInput) -> Void

    var body: some View {
        NavigationStack {
            HouseworkTemplateItemEditView(
                input: $input,
                isShowingKeyboard: _isShowingKeyboard,
                mode: mode,
                onTapClose: { dismiss() },
                onTapMemo: { isPresentedMemoEditSheet = true },
                onTapConfirm: { tappedConfirmButton() }
            )
            .sheet(isPresented: $isPresentedMemoEditSheet) {
                // すべて消したメモも空のまま残す。旧バージョンのアプリによる上書きを防ぐため（ADR-0034）
                HouseworkMemoEditScreen(memo: input.memo, isPremium: subscriptionStore.isPremium) { memo in
                    input.memo = memo
                } paywall: {
                    router.resolve(.paywall(step: .houseworkMemoLimit))
                }
                .trackScreenView(.houseworkMemoEdit)
            }
            .trackScreenView(.houseworkTemplateEdit)
        }
        .background {
            if isShowingKeyboard {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tappedBackgroundArea()
                    }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            onAppear()
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateItemEditModalScreen {

    func onAppear() {
        if case let .edit(before) = mode {
            // 編集時は元の入力値を表示しておく
            input = before
        } else {
            // 新規作成時はテキストフィールドを最初から表示しておく
            isShowingKeyboard = true
        }
    }

    func tappedBackgroundArea() {
        isShowingKeyboard = false
    }

    func tappedConfirmButton() {
        onConfirm(input)
        dismiss()
    }

}
