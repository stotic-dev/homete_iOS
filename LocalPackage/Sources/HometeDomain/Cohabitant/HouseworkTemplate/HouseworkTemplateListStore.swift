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
    private var templatesObserveTask: Task<Void, Never>?

    private let houseworkTemplateClient: HouseworkTemplateClient
    private let analyticsClient: AnalyticsClient
    private let daysListenerKey = "houseworkTemplateDaysListener"
    private let templatesListenerKey = "houseworkTemplatesListener"

    public var context: HouseworkTemplateContext {
        .init(metadata: templates.first, houseworkTemplate: selectedDays)
    }

    public init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        templates: [HouseworkTemplateMeta] = [],
        selectedDays: [HouseworkTemplateDay] = [],
        selectedTemplateId: String? = nil
    ) {
        self.houseworkTemplateClient = houseworkTemplateClient
        self.analyticsClient = analyticsClient
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
            await startObservingTemplates(cohabitantId)
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
        do {
            try await houseworkTemplateClient.upsertTemplate(newMeta, cohabitantId)
        } catch {
            analyticsClient.log(.houseworkTemplate(.apply(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.houseworkTemplate(.apply(isSuccess: true)))
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

        let changes = Self.itemChanges(from: selectedDays, to: days)
        do {
            try await houseworkTemplateClient.updateDays(
                days,
                templateId,
                cohabitantId,
                currentVersion
            )
        } catch {
            logItemChanges(changes, isSuccess: false)
            throw error
        }
        logItemChanges(changes, isSuccess: true)

        for day in days {
            if let index = selectedDays.firstIndex(where: { $0.dayOfWeek == day.dayOfWeek }) {
                selectedDays[index] = day
            } else {
                selectedDays.append(day)
            }
        }
    }

}

private extension HouseworkTemplateListStore {

    /// 保存前後の曜日別アイテムを比較し、追加・編集・削除されたアイテムのIDを洗い出す
    struct HouseworkTemplateItemChanges {

        let createdIds: [HouseworkTemplateItem.ItemId]
        let editedIds: [HouseworkTemplateItem.ItemId]
        let deletedIds: [HouseworkTemplateItem.ItemId]

    }

    /// アイテムIDごとに、内容と登録曜日の集合をまとめる
    static func itemDaysById(
        _ days: [HouseworkTemplateDay]
    ) -> [HouseworkTemplateItem.ItemId: (item: HouseworkTemplateItem, days: Set<DayOfWeek>)] {
        var result: [HouseworkTemplateItem.ItemId: (item: HouseworkTemplateItem, days: Set<DayOfWeek>)] = [:]
        for day in days {
            for item in day.items {
                result[item.id, default: (item, [])].days.insert(day.dayOfWeek)
            }
        }
        return result
    }

    /// 保存前後の状態を比較し、何が追加・編集・削除されたかを判定する
    /// - Note: 内容（タイトル・ポイント等）だけでなく、登録曜日の変更も編集として扱う
    static func itemChanges(
        from before: [HouseworkTemplateDay],
        to after: [HouseworkTemplateDay]
    ) -> HouseworkTemplateItemChanges {
        let beforeItems = itemDaysById(before)
        let afterItems = itemDaysById(after)

        let beforeIds = Set(beforeItems.keys)
        let afterIds = Set(afterItems.keys)

        let editedIds = beforeIds.intersection(afterIds).filter { id in
            beforeItems[id]?.item != afterItems[id]?.item || beforeItems[id]?.days != afterItems[id]?.days
        }

        return .init(
            createdIds: Array(afterIds.subtracting(beforeIds)),
            editedIds: Array(editedIds),
            deletedIds: Array(beforeIds.subtracting(afterIds))
        )
    }

    /// 変更されたアイテムの数だけ、それぞれのactionでイベントを送る
    func logItemChanges(_ changes: HouseworkTemplateItemChanges, isSuccess: Bool) {
        changes.createdIds.forEach { _ in analyticsClient.log(.houseworkTemplate(.create(isSuccess: isSuccess))) }
        changes.editedIds.forEach { _ in analyticsClient.log(.houseworkTemplate(.edit(isSuccess: isSuccess))) }
        changes.deletedIds.forEach { _ in analyticsClient.log(.houseworkTemplate(.delete(isSuccess: isSuccess))) }
    }

}

private extension HouseworkTemplateListStore {

    func startObservingTemplates(_ cohabitantId: String) async {
        let stream = await houseworkTemplateClient.addTemplatesSnapshotListener(
            templatesListenerKey,
            cohabitantId
        )

        templatesObserveTask = Task {
            for await templates in stream {
                // テンプレートが空の場合は何もしない
                guard let selectedTemplate = templates.first else { continue }

                // テンプレートが設定されたことを検知したら選択テンプレートを更新して、テンプレートの監視を終了する
                self.templates = templates
                self.selectedTemplateId = selectedTemplate.templateId
                await stopObservingTemplates()
            }
        }
    }

    func stopObservingTemplates() async {
        templatesObserveTask?.cancel()
        templatesObserveTask = nil
        await houseworkTemplateClient.removeListener(templatesListenerKey)
    }

}
