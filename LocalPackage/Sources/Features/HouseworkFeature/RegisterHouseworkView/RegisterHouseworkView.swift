//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FrequentHouseworkFeature
import HometeDomain
import HometeResources
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 家事の登録シート
/// - Note: 「いつもの家事」から選ぶのと「新しく入力」するのを同じ登録予定リストにためて、まとめて登録する
public struct RegisterHouseworkView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(HouseworkListStore.self) var houseworkListStore
    /// 同居人グループに未所属などで用意されていない場合は`nil`
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore: HouseworkTemplateListStore?
    @Environment(FrequentHouseworkStore.self) var frequentHouseworkStore: FrequentHouseworkStore?
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.frequentHouseworkContext) var frequentHouseworkContext
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.appDependencies.houseworkEntryHistoryClient) var houseworkEntryHistoryClient
    @Environment(\.routeResolver) var router
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var draft = RegisterHouseworkDraft()
    @State var selectedTab = RegisterSourceTab.manual
    @State var isPresentingPendingList = false
    @State var isPresentingDiscardAlert = false
    @State var isPresentingLimitAlert = false
    @State var isPresentingFrequentSaveFailure = false
    @State var isShowPaywall = false
    @State var isShowFrequentManagement = false

    @State var houseworkEntryHistoryList = HouseworkHistoryList(items: [])

    let dailyHouseworkList: DailyHouseworkList
    let step: HouseworkAnalyticsStep

    public static func make(dailyHouseworkList: DailyHouseworkList, step: HouseworkAnalyticsStep) -> some View {
        RegisterHouseworkView(dailyHouseworkList: dailyHouseworkList, step: step)
    }

    public var body: some View {
        NavigationStack {
            RegisterSourceTabs(selectedTab: $selectedTab) {
                frequentTab()
            } manualContent: {
                manualTab()
            }
            .navigationTitle("家事を追加")
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    tappedCancelButton()
                }
            }
            #if os(iOS)
            .toolbar {
                trailingNavigationItems()
            }
            #endif
            .safeAreaInset(edge: .bottom) {
                PendingEntriesBar(
                    entries: pendingEntries,
                    onTapSummary: { isPresentingPendingList = true }
                )
            }
        }
        .interactiveDismissDisabled(draft.hasInput)
        .sheet(isPresented: $isPresentingPendingList) {
            PendingEntriesSheet(
                entries: pendingEntries,
                onTapRemove: { entry in draft.remove(entry) },
                onTapClose: { isPresentingPendingList = false }
            )
        }
        .fullScreenCoverOnIOS(isPresented: $isShowFrequentManagement) {
            router.resolve(.frequentHouseworkManagement)
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
        .alert("入力した内容を破棄しますか？", isPresented: $isPresentingDiscardAlert) {
            Button("破棄する", role: .destructive) {
                dismiss()
            }
            Button("入力を続ける", role: .cancel) {}
        }
        .alert(
            "無料プランでは、いつもの家事を\(FrequentHouseworkLimitPolicy.freeLimit)件まで登録できます",
            isPresented: $isPresentingLimitAlert
        ) {
            Button("プレミアムプランを見る") {
                showPaywall()
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("プレミアムプランにすると、件数を気にせず登録できます。")
        }
        .alert("いつもの家事に保存できませんでした", isPresented: $isPresentingFrequentSaveFailure) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("家事は登録できています。いつもの家事への保存は、管理画面からやり直せます。")
        }
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
        .onAppear {
            onAppear()
        }
        .task {
            await loadEntryHistory()
        }
        .trackScreenView(.houseworkRegister)
    }

}

// MARK: - 表示内容

private extension RegisterHouseworkView {

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var pendingEntries: [PendingEntry] {
        draft.pendingEntries(context: frequentHouseworkContext)
    }

    /// 繰り返しを設定できるか
    /// - Note: テンプレートの読み込み中・読み込み失敗時は、既存のテンプレートの有無が分からず重複して作成しかねないので設定させない
    var canSetRecurrence: Bool {
        houseworkTemplateListStore?.loadState == .loaded
    }

    func frequentTab() -> some View {
        FrequentHouseworkPicker(
            filterCategories: frequentHouseworkContext.sections.map(\.category),
            sections: frequentHouseworkContext.sections,
            selectedIds: Set(draft.selectedFrequentItemIds),
            disabledIds: limitPolicy.unusableItemIds(in: frequentHouseworkContext),
            onTapItem: { item in draft.toggleFrequentItem(item.id) },
            onTapManage: { isShowFrequentManagement = true }
        )
    }

    // ナビゲーションバー右側のボタン
    // - Note: 1つの`ToolbarItem`にまとめるとiOS26でガラスの背景がひとつながりになり、登録ボタンに付けた
    //         ブランドカラーが効かずシステム標準の色で塗られる。`ToolbarSpacer`で項目を分けて出す
    #if os(iOS)
    @ToolbarContentBuilder
    func trailingNavigationItems() -> some ToolbarContent {
        if selectedTab == .frequent {
            ToolbarItem(placement: .topBarTrailing) {
                manageFrequentButton()
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            registerButton()
        }
    }
    #endif

    func registerButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "paperplane.fill") {
            tappedRegisterButton()
        }
        // 繰り返しの入力が途中のときは、入力中の家事を含めて登録できない
        .disabled(pendingEntries.isEmpty || !draft.input.recurrenceInput.isValid)
        .accessibilityLabel("\(pendingEntries.count)件登録する")
    }

    /// - Note: いつもの家事を選ぶときにしか使わないため、「いつもの家事」タブのときだけ出す
    func manageFrequentButton() -> some View {
        Button {
            isShowFrequentManagement = true
        } label: {
            Image(systemName: "list.bullet")
        }
        .foregroundStyle(.onSurface)
        .accessibilityLabel("いつもの家事を管理")
    }

    func manualTab() -> some View {
        ManualHouseworkForm(
            entry: $draft.input,
            categories: frequentHouseworkContext.categories,
            saveAsFrequentState: saveAsFrequentState,
            canSetRecurrence: canSetRecurrence,
            canQueue: draft.canQueueCurrentInput,
            history: houseworkEntryHistoryList.items,
            onTapQueue: { tappedQueueButton() },
            onTapHistory: { item in tappedEntryHistoryRow(item) },
            onTapSaveAsFrequentWhenLimitReached: { tappedSaveAsFrequentWhenLimitReached() }
        )
        .onChange(of: saveAsFrequentState) { _, newState in
            // 名前を変えて重複・上限に当たったら、オンのままにしない
            if !newState.isAvailable {
                draft.input.savesAsFrequent = false
            }
        }
    }

    var saveAsFrequentState: RegisterHouseworkDraft.SaveAsFrequentState {
        draft.saveAsFrequentState(context: frequentHouseworkContext, limitPolicy: limitPolicy)
    }

}

// MARK: - プレゼンテーションロジック

private extension RegisterHouseworkView {

    func onAppear() {
        // 繰り返しの各種類の初期値は、登録しようとしている日の曜日・日付にしておく
        draft.input.recurrenceInput = .init(
            kind: draft.input.recurrenceInput.kind,
            basedOn: dailyHouseworkList.metaData.indexedDate.value,
            calendar: calendar
        )
        selectedTab = .initial(hasFrequentHousework: !frequentHouseworkContext.isEmpty)
    }

    func tappedCancelButton() {
        guard draft.hasInput else {
            dismiss()
            return
        }
        isPresentingDiscardAlert = true
    }

    func tappedQueueButton() {
        draft.queueCurrentInput(id: UUID().uuidString)
    }

    /// - Note: 名前だけでなく完了ポイントも戻す。ポイントを毎回入れ直さずに済ませるのが履歴の目的のため
    func tappedEntryHistoryRow(_ item: HouseworkEntryHistoryItem) {
        draft.input.title = item.title
        draft.input.point = item.point
        houseworkEntryHistoryList.moveToFrontIfExists(item.title)
        let list = houseworkEntryHistoryList
        Task {
            await saveEntryHistory(list)
        }
    }

    func tappedSaveAsFrequentWhenLimitReached() {
        frequentHouseworkStore?.logLimitReached(step: .register)
        isPresentingLimitAlert = true
    }

    func tappedRegisterButton() {
        guard let cohabitantId else { return }
        let entries = pendingEntries
        guard !entries.isEmpty else { return }
        loadingState.task {
            await register(entries, cohabitantId: cohabitantId)
        }
    }

    /// 登録予定リストをまとめて登録する
    /// - Note: 家事の登録に失敗した場合はシートを閉じずに知らせ、登録予定リストを残す
    func register(_ entries: [PendingEntry], cohabitantId: String) async {
        await recordEntryHistory(entries)

        do {
            try await registerHousework(entries, cohabitantId: cohabitantId)
        } catch {
            print("Failed registering new housework items: \(error)")
            commonErrorContent = .init(error: error)
            return
        }
        await saveAsFrequentIfNeeded(entries, cohabitantId: cohabitantId)
    }

    /// 繰り返しなしはその日の家事として一括で、繰り返しありはテンプレートに追加する
    func registerHousework(_ entries: [PendingEntry], cohabitantId: String) async throws {
        let newItems = entries
            .filter { $0.recurrence == nil }
            .map { NewHouseworkEntry(item: makeHouseworkItem($0), source: $0.registerSource) }
        try await houseworkListStore.register(newItems: newItems, cohabitantId: cohabitantId, step: step)

        for entry in entries {
            guard let recurrence = entry.recurrence, let houseworkTemplateListStore else { continue }
            try await houseworkTemplateListStore.appendItemCreatingTemplateIfNeeded(
                makeTemplateItem(entry),
                recurrence: recurrence,
                cohabitantId: cohabitantId,
                newTemplateId: UUID().uuidString
            )
        }
    }

    /// 「いつもの家事に保存する」をオンにした家事を保存する
    /// - Note: 家事は登録できているため、ここだけ失敗した場合は知らせたうえでシートを閉じる
    func saveAsFrequentIfNeeded(_ entries: [PendingEntry], cohabitantId: String) async {
        let inputs = entries
            .filter(\.savesAsFrequent)
            .map { FrequentHouseworkInput(title: $0.title, point: $0.point, categoryId: $0.categoryId) }
        guard !inputs.isEmpty, let frequentHouseworkStore else {
            dismiss()
            return
        }
        do {
            try await frequentHouseworkStore.add(
                inputs,
                limitPolicy: limitPolicy,
                step: .register,
                cohabitantId: cohabitantId
            )
            dismiss()
        } catch {
            print("Failed saving frequent housework: \(error)")
            isPresentingFrequentSaveFailure = true
        }
    }

    func makeHouseworkItem(_ entry: PendingEntry) -> HouseworkItem {
        .init(
            id: UUID().uuidString,
            title: entry.title,
            point: entry.point,
            metaData: dailyHouseworkList.metaData
        )
    }

    func makeTemplateItem(_ entry: PendingEntry) -> HouseworkTemplateItem {
        .init(
            id: .init(uuid: UUID()),
            title: entry.title,
            point: entry.point,
            updatedAt: now
        )
    }

    func showPaywall() {
        analyticsClient.log(.paywall(.shown(step: .frequentHouseworkLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(
            step: .frequentHouseworkLimit,
            isPremium: subscriptionStore.isPremium
        )))
    }

}

// MARK: - 入力履歴

/// - Note: 履歴は入力を助けるための端末内の控えなので、読み書きに失敗しても家事の登録は止めない
private extension RegisterHouseworkView {

    func loadEntryHistory() async {
        do {
            houseworkEntryHistoryList = try await houseworkEntryHistoryClient.fetch()
        } catch {
            print("Failed loading housework entry history: \(error)")
        }
    }

    /// 「新しく入力」で登録した家事を履歴に残す
    func recordEntryHistory(_ entries: [PendingEntry]) async {
        let manualEntries = entries.filter { $0.registerSource == .manual }
        guard !manualEntries.isEmpty else { return }
        var list = houseworkEntryHistoryList
        for entry in manualEntries {
            list.addNewHistory(.init(title: entry.title, point: entry.point))
        }
        houseworkEntryHistoryList = list
        await saveEntryHistory(list)
    }

    func saveEntryHistory(_ list: HouseworkHistoryList) async {
        do {
            try await houseworkEntryHistoryClient.save(list)
        } catch {
            print("Failed saving housework entry history: \(error)")
        }
    }

}

#if DEBUG
extension HouseworkHistoryList {

    /// Preview用の、保存済みの入力履歴
    static let previewEntryHistory = HouseworkHistoryList(items: [
        .init(title: "洗濯", point: 20),
        .init(title: "掃除", point: 10),
    ])

}

extension RegisterHouseworkView {

    /// Preview用の、登録しようとしている日の家事一覧
    static func previewDailyHouseworkList() -> DailyHouseworkList {
        .init(
            items: [],
            metaData: .init(
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                expiredAt: .previewDate(year: 2026, month: 2, day: 1)
            )
        )
    }

    /// Preview用の、登録済みのいつもの家事
    static func previewFrequentHouseworkContext() -> FrequentHouseworkContext {
        .init(items: [
            .makeForPreview(id: "1", title: "風呂掃除", categoryId: "preset.cleaning"),
            .makeForPreview(id: "2", title: "換気扇", point: 30, categoryId: "preset.cleaning", sortOrder: 1),
            .makeForPreview(id: "3", title: "布団干し", point: 20, categoryId: "preset.laundry"),
        ])
    }

}

#Preview("RegisterHouseworkView_いつもの家事あり") {
    RegisterHouseworkView(
        draft: .init(selectedFrequentItemIds: ["1", "3"]),
        selectedTab: .frequent,
        dailyHouseworkList: RegisterHouseworkView.previewDailyHouseworkList(),
        step: .board
    )
    .environment(\.frequentHouseworkContext, RegisterHouseworkView.previewFrequentHouseworkContext())
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    .environment(HouseworkTemplateListStore(loadState: .loaded))
    .environment(SubscriptionStore())
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_いつもの家事なし") {
    RegisterHouseworkView(
        selectedTab: .manual,
        dailyHouseworkList: RegisterHouseworkView.previewDailyHouseworkList(),
        step: .board
    )
    .environment(\.appDependencies, .init(
        houseworkEntryHistoryClient: .init(fetch: { .previewEntryHistory })
    ))
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    .environment(HouseworkTemplateListStore(loadState: .loaded))
    .environment(SubscriptionStore())
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("RegisterHouseworkView_通信中") {
    RegisterHouseworkView(
        loadingState: .init(store: .init(isLoading: true)),
        dailyHouseworkList: RegisterHouseworkView.previewDailyHouseworkList(),
        step: .board
    )
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
    .environment(SubscriptionStore())
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
#endif
