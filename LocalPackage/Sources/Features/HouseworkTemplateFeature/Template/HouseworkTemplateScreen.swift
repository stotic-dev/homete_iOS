//
//  HouseworkTemplateScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkTemplateScreen: View {

    @Environment(\.now) var now
    @Environment(\.dismiss) var dismiss
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore
    @Environment(\.cohabitantMembers) var members

    @CommonError var commonErrorContent

    @State var templateEditStore: HouseworkTemplateEditStore
    @State var initialDraft: HouseworkTemplateDraft?
    @State var editingDraft: HouseworkTemplateDraft = .init()
    @State var editorContext: TemplateEditorContext = .init(currentActiveEditors: [], currentTemplateVersion: .zero)
    @State var shouldDismissOnErrorClose = false

    public static func make() -> some View {
        DependenciesInjectLayer {
            HouseworkTemplateScreen(
                templateEditStore: .init(houseworkTemplateClient: $0.houseworkTemplateClient)
            )
        }
    }

    public var body: some View {
        NavigationStack {
            HouseworkTemplateView(
                initialDraft: $initialDraft,
                draft: $editingDraft,
                editorContext: $editorContext
            )
        }
        .environment(templateEditStore)
        .commonError(content: $commonErrorContent, onDismiss: onDismissErrorAlert)
        .task {
            await onAppear()
        }
        .onDisappear {
            Task {
                await onDisappear()
            }
        }
        .onChange(of: templateEditStore.editors) {
            onChangeEditors()
        }
        .onChange(of: templateEditStore.currentVersion) {
            Task {
                await onChangeTemplateVersion()
            }
        }
        .onChange(of: houseworkTemplateListStore.selectedTemplateId) { oldValue, newValue in
            Task {
                await onChangeSelectedTemplateId(oldValue: oldValue, newValue: newValue)
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateScreen {

    func onAppear() async {
        // currentVersionで変更検知するためテンプレートの変更監視を止める
        await houseworkTemplateListStore.stopObservingDays()

        guard let templateId = houseworkTemplateListStore.selectedTemplateId,
              let cohabitantId = account.cohabitantId else { return }

        do {
            // 楽観ロックのための状態監視を開始
            try await templateEditStore.startEditing(
                templateId: templateId,
                cohabitantId: cohabitantId,
                userId: account.id,
                now: now
            )

            // 画面を開いたタイミングでの最新のテンプレート内容を設定
            let initialDraftOnAppear = HouseworkTemplateDraft.make(houseworkTemplateListStore.selectedDays)
            editingDraft = initialDraftOnAppear
            initialDraft = initialDraftOnAppear
        } catch {
            // 編集状態の監視・登録ができないと編集機能が成立しないため、アラート確認後に画面を閉じる
            shouldDismissOnErrorClose = true
            commonErrorContent = .init(error: error)
        }
    }

    func onDismissErrorAlert() {
        guard shouldDismissOnErrorClose else { return }
        shouldDismissOnErrorClose = false
        dismiss()
    }

    func onDisappear() async {
        guard let templateId = houseworkTemplateListStore.selectedTemplateId,
              let cohabitantId = account.cohabitantId else { return }

        await templateEditStore.stopEditing(
            templateId: templateId,
            cohabitantId: cohabitantId,
            userId: account.id
        )

        // テンプレートの変更検知で家事の内容をリアルタイムに更新するために監視を再開する
        await houseworkTemplateListStore.startObservingDays(
            templateId: templateId,
            cohabitantId: cohabitantId
        )
    }

    func onChangeEditors() {
        editorContext = editorContext.applyEditors(
            editors: templateEditStore.editors,
            members: members,
            now: now
        )
    }

    func onChangeTemplateVersion() async {
        // ローカルで保持しているテンプレートバージョンよりも大きいバージョンの場合に、コンフリクトが発生したとみなす
        guard editorContext.currentTemplateVersion < templateEditStore.currentVersion,
              let templateId = houseworkTemplateListStore.selectedTemplateId,
              let cohabitantId = account.cohabitantId else { return }

        await loadCurrentTemplate(templateId: templateId, cohabitantId: cohabitantId)
    }

    func onChangeSelectedTemplateId(oldValue: String?, newValue: String?) async {
        // テンプレート画面内でテンプレートがない状態からテンプレートが作成されたことを検知したら、
        // 現在のテンプレートの内容をロードする
        guard oldValue == nil,
              let newValue,
              let cohabitantId = account.cohabitantId else { return }

        await loadCurrentTemplate(templateId: newValue, cohabitantId: cohabitantId)
    }

    func loadCurrentTemplate(templateId: String, cohabitantId: String) async {
        do {
            // バージョンが変わったらテンプレートの内容を再ロードする
            try await houseworkTemplateListStore.loadDays(templateId: templateId, cohabitantId: cohabitantId)
            // 未保存の変更が残っている場合はコンフリクトアラートで解決されるまでバージョンを進めない
            // （先にバージョンを進めてしまうと、アラートを「キャンセル」した後の保存で楽観ロックが素通りしてしまうため）
            let hasUnresolvedConflict = initialDraft?.hasUnsavedChanges(comparedTo: editingDraft) ?? false
            initialDraft = .make(houseworkTemplateListStore.selectedDays)
            if !hasUnresolvedConflict {
                editorContext = editorContext.applyEditors(templateEditStore.currentVersion)
            }
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

}
