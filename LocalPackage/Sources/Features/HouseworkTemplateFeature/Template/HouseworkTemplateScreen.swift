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
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore
    @Environment(\.cohabitantMembers) var members

    @State var templateEditStore: HouseworkTemplateEditStore
    @State var initialDraft: HouseworkTemplateDraft = .init()
    @State var editorContext: TemplateEditorContext = .init(currentActiveEditors: [], currentTemplateVersion: .zero)

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
                editorContext: editorContext
            )
        }
        .environment(templateEditStore)
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
            initialDraft = .make(houseworkTemplateListStore.selectedDays)
        } catch {
            // TODO: エラーハンドリング
        }
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
        guard let templateId = houseworkTemplateListStore.selectedTemplateId,
              let cohabitantId = account.cohabitantId else { return }

        do {
            // バージョンが変わったらテンプレートの内容を再ロードする
            try await houseworkTemplateListStore.loadDays(templateId: templateId, cohabitantId: cohabitantId)
            initialDraft = .make(houseworkTemplateListStore.selectedDays)
            editorContext = editorContext.applyEditors(templateEditStore.currentVersion)
        } catch {
            // TODO: エラーハンドリング
        }
    }

}
