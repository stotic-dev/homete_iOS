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
                initialDraft: initialDraft,
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
            onChangeTemplateVersion()
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateScreen {

    func onAppear() async {
        guard let templateId = houseworkTemplateListStore.templates.first?.templateId,
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
        guard let templateId = houseworkTemplateListStore.templates.first?.templateId,
              let cohabitantId = account.cohabitantId else { return }

        await templateEditStore.stopEditing(
            templateId: templateId,
            cohabitantId: cohabitantId,
            userId: account.id
        )
    }

    func onChangeEditors() {
        editorContext = editorContext.applyEditors(
            editors: templateEditStore.editors,
            members: members,
            now: now
        )
    }

    func onChangeTemplateVersion() {
        editorContext = editorContext.applyEditors(templateEditStore.currentVersion)
    }

}
