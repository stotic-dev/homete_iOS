//
//  RegisterHouseworkScreen.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import HouseworkFeatureUI
import FrequentHouseworkFeatureUI
import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事の登録シート
/// - Note: 「いつもの家事」から選ぶのと「新しく入力」するのを同じ登録予定リストにためて、まとめて登録する
public struct RegisterHouseworkScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(HouseworkListStore.self) var houseworkListStore
    /// 同居人グループに未所属などで用意されていない場合は`nil`
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore: HouseworkTemplateListStore?
    @Environment(FrequentHouseworkStore.self) var frequentHouseworkStore: FrequentHouseworkStore?
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.frequentHouseworkContext) var frequentHouseworkContext
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.appDependencies.houseworkEntryHistoryClient) var houseworkEntryHistoryClient
    @Environment(\.appDependencies.screenTutorialStateClient) var screenTutorialStateClient
    @Environment(\.routeResolver) var router
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.loginContext.account.id) var accountId
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
    @State var isPresentingMemoEditSheet = false
    @State var imagePickSource: HouseworkImagePickSource?
    @State var isShowImagePaywall = false
    /// 外す前の確認で確かめている、入力中の家事の画像
    @State var removingImageId: HouseworkImageUpload.ID?
    @State var imageError: HouseworkImageError?

    @State var houseworkEntryHistoryList = HouseworkHistoryList(items: [])
    /// 初めて開いたときに出すチュートリアル。Environmentの依存から作るため、表示されてから用意する
    @State var tutorialStore: ScreenTutorialStore<RegisterHouseworkTutorialStep>?

    let dailyHouseworkList: DailyHouseworkList
    let step: HouseworkAnalyticsStep

    public static func make(dailyHouseworkList: DailyHouseworkList, step: HouseworkAnalyticsStep) -> some View {
        RegisterHouseworkScreen(dailyHouseworkList: dailyHouseworkList, step: step)
    }

    public var body: some View {
        RegisterHouseworkView(
            draft: $draft,
            selectedTab: $selectedTab,
            frequentHouseworkContext: frequentHouseworkContext,
            isPremium: subscriptionStore.isPremium,
            canSetRecurrence: canSetRecurrence,
            history: houseworkEntryHistoryList.items,
            isCameraAvailable: CameraPicker.isAvailable,
            tutorialStep: tutorialStep,
            actions: .init(
                onTapCancel: { tappedCancelButton() },
                onTapRegister: { tappedRegisterButton() },
                onTapQueue: { tappedQueueButton() },
                onTapPendingEntries: { isPresentingPendingList = true },
                onTapManageFrequent: { isShowFrequentManagement = true },
                onTapHistory: { item in tappedEntryHistoryRow(item) },
                onTapSaveAsFrequentWhenLimitReached: { tappedSaveAsFrequentWhenLimitReached() },
                onTapMemo: { isPresentingMemoEditSheet = true },
                onTapAddImage: { source in imagePickSource = source },
                onTapImagePremium: { isShowImagePaywall = true },
                onTapImage: { imageId in removingImageId = imageId }
            ),
            thumbnail: { image in
                HouseworkImageComponent(source: .pending(image), maxPixelSize: 300, contentMode: .fill)
            },
            tutorialCard: { tutorialCard() }
        )
        // チュートリアルの表示中は、カードのボタンで閉じてもらう
        .interactiveDismissDisabled(draft.hasInput || tutorialStep != nil)
        .onChange(of: saveAsFrequentState) { _, newState in
            // 名前を変えて重複・上限に当たったら、オンのままにしない
            if !newState.isAvailable {
                draft.input.savesAsFrequent = false
            }
        }
        .onChange(of: tutorialStep) { _, newStep in
            onChangeTutorialStep(newStep)
        }
        .sheet(isPresented: $isPresentingPendingList) {
            PendingEntriesSheet(
                entries: pendingEntries,
                onTapRemove: { entry in draft.remove(entry) },
                onTapClose: { isPresentingPendingList = false }
            )
        }
        .sheet(isPresented: $isPresentingMemoEditSheet) {
            HouseworkMemoEditScreen(memo: draft.input.memo, isPremium: subscriptionStore.isPremium) { memo in
                // まだ保存していない家事なので、すべて消したメモは「メモなし」に戻す
                draft.input.memo = memo.isEmpty ? nil : memo
            } paywall: {
                router.resolve(.paywall(step: .houseworkMemoLimit))
            }
            .trackScreenView(.houseworkMemoEdit)
        }
        .houseworkImagePicker(source: $imagePickSource, maxSelectionCount: remainingImageCount) { originals in
            pickedImages(originals)
        }
        .houseworkImageErrorAlert($imageError)
        .fullScreenCoverOnIOS(isPresented: $isShowImagePaywall) {
            router.resolve(.paywall(step: .houseworkImage))
        }
        .confirmationDialog(
            .localized("この画像を外しますか？"),
            isPresented: .init(get: { removingImageId != nil }, set: { if !$0 { removingImageId = nil } }),
            titleVisibility: .visible,
            presenting: removingImageId
        ) { imageId in
            Button(.localized("外す"), role: .destructive) {
                draft.removeImage(imageId)
            }
            Button(.localized("キャンセル"), role: .cancel) {}
        }
        .fullScreenCoverOnIOS(isPresented: $isShowFrequentManagement) {
            router.resolve(.frequentHouseworkManagement)
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            content: { router.resolve(.paywall(step: .frequentHouseworkLimit)) }
        )
        .alert(.localized("入力した内容を破棄しますか？"), isPresented: $isPresentingDiscardAlert) {
            Button(.localized("破棄する"), role: .destructive) {
                dismiss()
            }
            Button(.localized("入力を続ける"), role: .cancel) {}
        }
        .alert(
            .localized("無料プランでは、いつもの家事を\(FrequentHouseworkLimitPolicy.freeLimit)件まで登録できます"),
            isPresented: $isPresentingLimitAlert
        ) {
            Button(.localized("プレミアムプランを見る")) {
                showPaywall()
            }
            Button(.localized("閉じる"), role: .cancel) {}
        } message: {
            Text("プレミアムプランにすると、件数を気にせず登録できます。", bundle: #bundle)
        }
        .alert(.localized("いつもの家事に保存できませんでした"), isPresented: $isPresentingFrequentSaveFailure) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("家事は登録できています。いつもの家事への保存は、管理画面からやり直せます。", bundle: #bundle)
        }
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
        .onAppear {
            onAppear()
        }
        .task {
            await loadEntryHistory()
        }
        .task {
            await startTutorialIfNeeded()
        }
        .trackScreenView(.houseworkRegister)
    }

}

// MARK: - 表示内容

private extension RegisterHouseworkScreen {

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var memoLimitPolicy: HouseworkMemoLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var imagePolicy: HouseworkImagePolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    /// くり返す家事はテンプレートに登録するため、画像を添えられない。選んだ画像は入力に残したまま隠し、
    /// くり返しをやめたらまた出す（登録予定リストには載せない）
    var canAddImages: Bool {
        draft.input.canAttachImages
    }

    var imageAddState: HouseworkImageAddState {
        .make(canAdd: canAddImages, policy: imagePolicy, currentCount: draft.input.images.count)
    }

    var remainingImageCount: Int {
        imagePolicy.addableCount(currentCount: draft.input.images.count)
    }

    var pendingEntries: [PendingEntry] {
        draft.pendingEntries(context: frequentHouseworkContext)
    }

    /// 繰り返しを設定できるか
    /// - Note: テンプレートの読み込み中・読み込み失敗時は、既存のテンプレートの有無が分からず重複して作成しかねないので設定させない
    var canSetRecurrence: Bool {
        houseworkTemplateListStore?.loadState == .loaded
    }

    @ViewBuilder
    func tutorialCard() -> some View {
        if let tutorialStore,
           let step = tutorialStore.currentStep {
            RegisterHouseworkTutorialCard(
                step: step,
                steps: tutorialStore.steps,
                onTapNext: {
                    Task {
                        await tutorialStore.next(from: step)
                    }
                },
                onTapBack: {
                    tutorialStore.back(from: step)
                },
                onTapClose: {
                    Task {
                        await tutorialStore.close()
                    }
                }
            )
        }
    }

    var tutorialStep: RegisterHouseworkTutorialStep? {
        tutorialStore?.currentStep
    }

    var saveAsFrequentState: RegisterHouseworkDraft.SaveAsFrequentState {
        draft.saveAsFrequentState(context: frequentHouseworkContext, limitPolicy: limitPolicy)
    }

}

// MARK: - プレゼンテーションロジック

private extension RegisterHouseworkScreen {

    func onAppear() {
        // 繰り返しの各種類の初期値は、登録しようとしている日の曜日・日付にしておく
        draft.input.recurrenceInput = .init(
            kind: draft.input.recurrenceInput.kind,
            basedOn: dailyHouseworkList.metaData.indexedDate.value,
            calendar: calendar
        )
        selectedTab = .initial(hasFrequentHousework: !frequentHouseworkContext.isEmpty)
    }

    /// - Note: 無料プランでいつもの家事が上限に達していると、保存のスイッチの代わりにプランの案内が出て
    ///         説明どおりに操作できないため、いつもの家事に保存するステップを除く
    func startTutorialIfNeeded() async {
        let store = tutorialStore ?? ScreenTutorialStore(
            stateClient: screenTutorialStateClient,
            analyticsClient: analyticsClient
        )
        tutorialStore = store
        let isFrequentLimitReached = limitPolicy.isLimitReached(currentCount: frequentHouseworkContext.items.count)
        await store.startIfNeeded(skipping: isFrequentLimitReached ? [.saveAsFrequent] : [])
    }

    /// 「続けて入力する」と「いつもの家事に保存する」は「新しく入力」にしかないため、説明するときに切り替える
    func onChangeTutorialStep(_ step: RegisterHouseworkTutorialStep?) {
        switch step {
        case .queue, .saveAsFrequent:
            selectedTab = .manual

        case .inputSource, nil:
            break
        }
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
            if let error = error as? HouseworkImageError {
                imageError = error
            } else {
                commonErrorContent = .init(error: error)
            }
            return
        }
        await saveAsFrequentIfNeeded(entries, cohabitantId: cohabitantId)
    }

    /// 繰り返しなしはその日の家事として一括で、繰り返しありはテンプレートに追加する
    func registerHousework(_ entries: [PendingEntry], cohabitantId: String) async throws {
        let newItems = entries
            .filter { $0.recurrence == nil }
            .map { NewHouseworkEntry(item: makeHouseworkItem($0), source: $0.registerSource, images: $0.images) }
        try await houseworkListStore.register(
            newItems: newItems,
            cohabitantId: cohabitantId,
            step: step,
            memoLimitPolicy: memoLimitPolicy,
            imagePolicy: imagePolicy,
            uploaderId: accountId
        )

        for entry in entries {
            guard let recurrence = entry.recurrence, let houseworkTemplateListStore else { continue }
            try await houseworkTemplateListStore.appendItemCreatingTemplateIfNeeded(
                makeTemplateItem(entry),
                recurrence: recurrence,
                cohabitantId: cohabitantId,
                memoLimitPolicy: memoLimitPolicy,
                newTemplateId: UUID().uuidString
            )
        }
    }

    /// 「いつもの家事に保存する」をオンにした家事を保存する
    /// - Note: 家事は登録できているため、ここだけ失敗した場合は知らせたうえでシートを閉じる
    func saveAsFrequentIfNeeded(_ entries: [PendingEntry], cohabitantId: String) async {
        let inputs = entries
            .filter(\.savesAsFrequent)
            .map { FrequentHouseworkInput(title: $0.title, point: $0.point, categoryId: $0.categoryId, memo: $0.memo) }
        guard !inputs.isEmpty, let frequentHouseworkStore else {
            dismiss()
            return
        }
        do {
            try await frequentHouseworkStore.add(
                inputs,
                limitPolicy: limitPolicy,
                memoLimitPolicy: memoLimitPolicy,
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
            metaData: dailyHouseworkList.metaData,
            memo: entry.memo
        )
    }

    func makeTemplateItem(_ entry: PendingEntry) -> HouseworkTemplateItem {
        .init(
            id: .init(uuid: UUID()),
            title: entry.title,
            point: entry.point,
            updatedAt: now,
            memo: entry.memo
        )
    }

    func showPaywall() {
        isShowPaywall = true
    }

    /// 選んだ画像を縮小・圧縮して、入力中の家事に添える（上げるのは登録するとき）
    func pickedImages(_ originals: [@Sendable () async -> Data?]) {
        loadingState.task {
            do {
                let uploads = try await HouseworkImageUpload.make(loading: originals)
                // 読み込んでいる間に枚数が変わっていても、上限を超えて添えない
                draft.input.images += uploads.prefix(remainingImageCount)
            } catch let error as HouseworkImageError {
                imageError = error
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

}

// MARK: - 入力履歴

/// - Note: 履歴は入力を助けるための端末内の控えなので、読み書きに失敗しても家事の登録は止めない
private extension RegisterHouseworkScreen {

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
