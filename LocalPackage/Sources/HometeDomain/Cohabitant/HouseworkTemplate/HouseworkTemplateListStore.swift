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
    public private(set) var monthlyItems: [HouseworkTemplateMonthlyItem]
    public private(set) var selectedTemplateId: String?
    /// テンプレートの初回ロードの状態
    public private(set) var loadState: ListenerLoadState = .loading

    private var daysObserveTask: Task<Void, Never>?
    private var monthlyItemsObserveTask: Task<Void, Never>?
    private var templatesObserveTask: Task<Void, Never>?

    private let houseworkTemplateClient: HouseworkTemplateClient
    private let analyticsClient: AnalyticsClient
    private let daysListenerKey = "houseworkTemplateDaysListener"
    private let monthlyItemsListenerKey = "houseworkTemplateMonthlyItemsListener"
    private let templatesListenerKey = "houseworkTemplatesListener"

    public var context: HouseworkTemplateContext {
        .init(metadata: templates.first, houseworkTemplate: selectedDays, monthlyItems: monthlyItems)
    }

    public init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        templates: [HouseworkTemplateMeta] = [],
        selectedDays: [HouseworkTemplateDay] = [],
        monthlyItems: [HouseworkTemplateMonthlyItem] = [],
        selectedTemplateId: String? = nil,
        loadState: ListenerLoadState = .loading
    ) {
        self.houseworkTemplateClient = houseworkTemplateClient
        self.analyticsClient = analyticsClient
        self.templates = templates
        self.selectedDays = selectedDays
        self.monthlyItems = monthlyItems
        self.selectedTemplateId = selectedTemplateId
        self.loadState = loadState
    }

    /// Storeの初回設定を行う
    /// - Note: 失敗した場合は呼び出し元でハンドリングできるようrethrowしつつ、
    ///         画面側がリトライ導線を出せるように`loadState`にも記録する。
    public func configure(cohabitantId: String) async throws {
        loadState = .loading
        do {
            try await loadTemplates(cohabitantId: cohabitantId)

            if let selectedTemplateId = templates.first?.templateId {
                self.selectedTemplateId = selectedTemplateId
                try await loadDays(templateId: selectedTemplateId, cohabitantId: cohabitantId)
                await loadMonthlyItems(templateId: selectedTemplateId, cohabitantId: cohabitantId)
                await startObservingItems(templateId: selectedTemplateId, cohabitantId: cohabitantId)
            } else {
                await startObservingTemplates(cohabitantId)
            }
            loadState = .loaded
        } catch {
            loadState = .failed(DomainError.make(error) ?? .other)
            throw error
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

    /// 指定テンプレートの毎月の家事をワンショット取得する
    /// - Note: 失敗しても throw せず、`monthlyItems` を変えずにログだけ残す。毎月の家事は後から足した機能なので、
    ///         その取得失敗（`MonthlyItems` のセキュリティルールが未デプロイの環境など）で、毎週の家事を含む
    ///         テンプレート全体の読み込みを失敗扱いにしないため
    public func loadMonthlyItems(templateId: String, cohabitantId: String) async {
        do {
            monthlyItems = try await houseworkTemplateClient.fetchMonthlyItems(cohabitantId, templateId)
        } catch {
            print("failed to fetch monthly housework template items: \(error)")
        }
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

    /// 指定テンプレートの Days / MonthlyItems の SnapshotListener を開始する
    /// - Note: 既に監視中の場合は、監視を二重にしないよう先に解除してから開始し直す
    public func startObservingItems(templateId: String, cohabitantId: String) async {
        await stopObservingItems()

        let daysStream = await houseworkTemplateClient.addDaysSnapshotListener(
            daysListenerKey,
            templateId,
            cohabitantId
        )
        daysObserveTask = Task {
            for await currentDays in daysStream {
                self.selectedDays = currentDays
            }
        }

        let monthlyItemsStream = await houseworkTemplateClient.addMonthlyItemsSnapshotListener(
            monthlyItemsListenerKey,
            templateId,
            cohabitantId
        )
        monthlyItemsObserveTask = Task {
            for await currentMonthlyItems in monthlyItemsStream {
                self.monthlyItems = currentMonthlyItems
            }
        }
    }

    /// Days / MonthlyItems の SnapshotListener を解除する
    public func stopObservingItems() async {
        daysObserveTask?.cancel()
        daysObserveTask = nil
        monthlyItemsObserveTask?.cancel()
        monthlyItemsObserveTask = nil
        await houseworkTemplateClient.removeListener(daysListenerKey)
        await houseworkTemplateClient.removeListener(monthlyItemsListenerKey)
    }

    /// 曜日定義と毎月の家事を一括保存する。version の楽観的ロックで競合が発生した場合は `HouseworkTemplateError.versionConflict` を throw する。
    /// - Parameters:
    ///   - days: 書き込む曜日定義。成功時には `selectedDays` をローカル更新する（既存の dayOfWeek は置換、未登録は追加）
    ///   - monthlyItems: 保存後の毎月の家事の全件。現在の `monthlyItems` との差分だけを書き込み、成功時には置き換える
    /// - Note: 書き込む内容がない場合は no-op。
    public func saveTemplate(
        days: [HouseworkTemplateDay],
        monthlyItems: [HouseworkTemplateMonthlyItem],
        templateId: String,
        cohabitantId: String,
        currentVersion: Int
    ) async throws {
        let afterMonthlyIds = Set(monthlyItems.map(\.id))
        let update = HouseworkTemplateUpdate(
            days: days,
            upsertedMonthlyItems: monthlyItems.filter { !self.monthlyItems.contains($0) },
            deletedMonthlyItemIds: self.monthlyItems.map(\.id).filter { !afterMonthlyIds.contains($0) }
        )
        guard !update.isEmpty else { return }

        let changes = Self.itemChanges(
            from: .init(days: selectedDays, monthlyItems: self.monthlyItems),
            to: .init(days: days, monthlyItems: monthlyItems)
        )
        do {
            try await houseworkTemplateClient.updateTemplate(
                update,
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
        self.monthlyItems = monthlyItems
    }

    /// 選択中のテンプレートに家事を1件追加する。テンプレートがまだなければ作成してから追加する（家事登録画面用）
    /// - Parameter newTemplateId: テンプレートを新規作成する場合に使うID
    /// - Note: 新規作成したテンプレートは、追加した家事がすぐ家事一覧に表示されるよう、その場で選択して監視を始める
    /// - Throws: 読み込みが終わっていない場合は `HouseworkTemplateError.notLoaded`。
    ///           `selectedTemplateId` が `nil` でも「テンプレートが無い」とは限らず、重複して作成してしまうため
    public func appendItemCreatingTemplateIfNeeded(
        _ item: HouseworkTemplateItem,
        recurrence: HouseworkRecurrence,
        cohabitantId: String,
        newTemplateId: @autoclosure () -> String
    ) async throws {
        guard loadState == .loaded else {
            throw HouseworkTemplateError.notLoaded
        }

        let templateId: String
        if let selectedTemplateId {
            templateId = selectedTemplateId
        } else {
            templateId = newTemplateId()
            try await createTemplate(templateId: templateId, name: "default", cohabitantId: cohabitantId)
            selectedTemplateId = templateId
            await startObservingItems(templateId: templateId, cohabitantId: cohabitantId)
        }
        try await appendItem(item, recurrence: recurrence, templateId: templateId, cohabitantId: cohabitantId)
    }

    /// テンプレートに家事を1件追加する（家事登録画面用）
    /// - Note: 画面の表示にはSnapshotListener経由で反映される
    public func appendItem(
        _ item: HouseworkTemplateItem,
        recurrence: HouseworkRecurrence,
        templateId: String,
        cohabitantId: String
    ) async throws {
        do {
            try await houseworkTemplateClient.appendItem(item, recurrence, templateId, cohabitantId)
        } catch {
            analyticsClient.log(.houseworkTemplate(.create(isSuccess: false, step: .register, recurrence: recurrence)))
            throw error
        }
        analyticsClient.log(.houseworkTemplate(.create(isSuccess: true, step: .register, recurrence: recurrence)))
    }

}

private extension HouseworkTemplateListStore {

    /// 保存前後の曜日別アイテムを比較し、追加・編集・削除されたアイテムのIDを洗い出す
    struct HouseworkTemplateItemChanges {

        /// 追加された家事の繰り返し方
        let created: [HouseworkRecurrence]
        /// 編集された家事の編集後の繰り返し方
        let edited: [HouseworkRecurrence]
        let deletedIds: [HouseworkTemplateItem.ItemId]

    }

    /// 比較対象となるテンプレートの内容
    struct TemplateSnapshot {

        let days: [HouseworkTemplateDay]
        let monthlyItems: [HouseworkTemplateMonthlyItem]

    }

    /// アイテムIDごとに、内容と繰り返し方をまとめる
    static func itemRecurrenceById(
        _ snapshot: TemplateSnapshot
    ) -> [HouseworkTemplateItem.ItemId: (item: HouseworkTemplateItem, recurrence: HouseworkRecurrence)] {
        var weeklyItems: [HouseworkTemplateItem.ItemId: (item: HouseworkTemplateItem, days: Set<DayOfWeek>)] = [:]
        for day in snapshot.days {
            for item in day.items {
                weeklyItems[item.id, default: (item, [])].days.insert(day.dayOfWeek)
            }
        }

        var result = weeklyItems.mapValues { (item: $0.item, recurrence: HouseworkRecurrence.weekly($0.days)) }
        for monthlyItem in snapshot.monthlyItems {
            result[monthlyItem.id] = (monthlyItem.item, .monthly(monthlyItem.rule))
        }
        return result
    }

    /// 保存前後の状態を比較し、何が追加・編集・削除されたかを判定する
    /// - Note: 内容（タイトル・ポイント等）だけでなく、繰り返し方（登録曜日・毎週と毎月の切り替えなど）の変更も編集として扱う
    static func itemChanges(
        from before: TemplateSnapshot,
        to after: TemplateSnapshot
    ) -> HouseworkTemplateItemChanges {
        let beforeItems = itemRecurrenceById(before)
        let afterItems = itemRecurrenceById(after)

        let beforeIds = Set(beforeItems.keys)
        let afterIds = Set(afterItems.keys)

        let editedIds = beforeIds.intersection(afterIds).filter { id in
            beforeItems[id]?.item != afterItems[id]?.item || beforeItems[id]?.recurrence != afterItems[id]?.recurrence
        }

        return .init(
            created: afterIds.subtracting(beforeIds).compactMap { afterItems[$0]?.recurrence },
            edited: editedIds.compactMap { afterItems[$0]?.recurrence },
            deletedIds: Array(beforeIds.subtracting(afterIds))
        )
    }

    /// 変更されたアイテムの数だけ、それぞれのactionでイベントを送る
    func logItemChanges(_ changes: HouseworkTemplateItemChanges, isSuccess: Bool) {
        for recurrence in changes.created {
            analyticsClient.log(.houseworkTemplate(.create(
                isSuccess: isSuccess,
                step: .template,
                recurrence: recurrence
            )))
        }
        for recurrence in changes.edited {
            analyticsClient.log(.houseworkTemplate(.edit(isSuccess: isSuccess, recurrence: recurrence)))
        }
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
