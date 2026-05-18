//
//  HouseworkTemplateListStore.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import Observation

@MainActor
@Observable
public final class HouseworkTemplateListStore {

    public private(set) var templates: [HouseworkTemplateMeta]
    public private(set) var selectedDays: [HouseworkTemplateDay]
    public private(set) var selectedTemplateId: String?

    private var daysObserveTask: Task<Void, Never>?

    private let houseworkTemplateClient: HouseworkTemplateClient
    private let daysListenerKey = "houseworkTemplateDaysListener"

    public var context: HouseworkTemplateContext {
        .init(metadata: templates.first, houseworkTemplate: selectedDays)
    }

    public init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        templates: [HouseworkTemplateMeta] = [],
        selectedDays: [HouseworkTemplateDay] = [],
        selectedTemplateId: String? = nil
    ) {
        self.houseworkTemplateClient = houseworkTemplateClient
        self.templates = templates
        self.selectedDays = selectedDays
        self.selectedTemplateId = selectedTemplateId
    }

    /// Storeの初回設定を行う
    public func configure(cohabitantId: String) async throws {
        try await loadTemplates(cohabitantId: cohabitantId)

        if let selectedTemplateId = templates.first?.templateId {
            self.selectedTemplateId = selectedTemplateId
            try await loadDays(templateId: selectedTemplateId, cohabitantId: cohabitantId)
            await startObservingDays(templateId: selectedTemplateId, cohabitantId: cohabitantId)
        } else {
            // TODO: テンプレートリストを監視して、作成されたらテンプレートを選択してテンプレートの内容を監視する
        }
    }

    /// テンプレート一覧をワンショット取得する
    public func loadTemplates(cohabitantId: String) async throws {
        templates = try await houseworkTemplateClient.fetchTemplates(cohabitantId)
    }

    /// 指定テンプレートの曜日別定義をワンショット取得する
    public func loadDays(templateId: String, cohabitantId: String) async throws {
        selectedDays = try await houseworkTemplateClient.fetchDays(cohabitantId, templateId)
    }

    /// 新規テンプレートを作成する
    public func createTemplate(
        templateId: String,
        name: String,
        cohabitantId: String
    ) async throws {
        let newMeta = HouseworkTemplateMeta(
            templateId: templateId,
            name: name
        )
        try await houseworkTemplateClient.upsertTemplate(newMeta, cohabitantId)
        templates.append(newMeta)
        // 選択中のテンプレートを作成したテンプレートに更新
        selectedDays = []
    }

    /// 指定テンプレートの Days SnapshotListener を開始する
    public func startObservingDays(templateId: String, cohabitantId: String) async {
        let stream = await houseworkTemplateClient.addDaysSnapshotListener(
            daysListenerKey,
            templateId,
            cohabitantId
        )
        daysObserveTask = Task {

            for await currentDays in stream {
                self.selectedDays = currentDays
            }
        }
    }

    /// Days SnapshotListener を解除する
    public func stopObservingDays() async {
        daysObserveTask?.cancel()
        daysObserveTask = nil
        await houseworkTemplateClient.removeListener(daysListenerKey)
    }

    /// 曜日定義を一括保存する。version の楽観的ロックで競合が発生した場合は `HouseworkTemplateError.versionConflict` を throw する。
    /// 成功時には `selectedDays` をローカル更新する（既存の dayOfWeek は置換、未登録は追加）。
    /// 空配列が渡された場合は no-op。
    public func saveDays(
        _ days: [HouseworkTemplateDay],
        templateId: String,
        cohabitantId: String,
        currentVersion: Int
    ) async throws {
        guard !days.isEmpty else { return }
        try await houseworkTemplateClient.updateDays(
            days,
            templateId,
            cohabitantId,
            currentVersion
        )

        for day in days {
            if let index = selectedDays.firstIndex(where: { $0.dayOfWeek == day.dayOfWeek }) {
                selectedDays[index] = day
            } else {
                selectedDays.append(day)
            }
        }
    }

}
