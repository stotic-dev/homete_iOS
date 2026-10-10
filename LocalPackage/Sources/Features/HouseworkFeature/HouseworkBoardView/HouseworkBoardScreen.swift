//
//  HouseworkBoardScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事ボードの画面
///
/// Storeの購読・家事の操作・シートの表示・画面遷移を受け持ち、見た目は`HouseworkBoardView`に任せる。
public struct HouseworkBoardScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.routeResolver) var router
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var members
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(PendingNotificationRouteStore.self) var pendingNotificationRouteStore

    @State var houseworkBoardList: HouseworkBoardList = .init(items: [])
    @State var dateList = HouseworkDateList()
    @State var navigationPath = AppNavigationPath<HouseworkBoardRoute>()
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var isPresentingAddHouseworkView = false
    @State var isShowHouseworkTemplate = false
    @State var isShowPaywall = false
    @State var isSelecting = false
    /// 複数選択モードで選択中の家事のID
    @State var selectedHouseworkIDs: Set<String> = []
    /// クイックアクションの「完了にする」で、担当者を選ぶハーフモーダルを出している家事
    @State var completingItem: HouseworkBoardItem?
    /// クイックアクションの「ありがとう」で、メッセージを入力するハーフモーダルを出している家事
    @State var thankingItem: HouseworkBoardItem?
    /// クイックアクションの「手伝った人を追加」で、担当者を選ぶハーフモーダルを出している家事
    @State var addingHelperItem: HouseworkBoardItem?
    /// 初めてありがとうを伝えた回数。増えるたびにありがとうの演出を出す
    @State var thanksFeedbackCount = 0
    /// ハーフモーダルで初めてありがとうを伝え、モーダルが閉じきるのを待って演出を出す
    @State var hasPendingThanksFeedback = false

    @LoadingState var loadingState
    @CommonError var commonError

    let houseworkListStore: HouseworkListStore?
    let houseworkTemplateListStore: HouseworkTemplateListStore?

    public static func make(
        houseworkListStore: HouseworkListStore?,
        houseworkTemplateListStore: HouseworkTemplateListStore?
    ) -> some View {
        HouseworkBoardScreen(
            houseworkListStore: houseworkListStore,
            houseworkTemplateListStore: houseworkTemplateListStore
        )
    }

    public var body: some View {
        if let houseworkListStore {
            board(houseworkListStore: houseworkListStore)
                .environment(houseworkListStore)
                .environment(houseworkTemplateListStore)
                .onAppear {
                    withAnimation {
                        onAppeare(with: houseworkListStore)
                    }
                }
                // 繰り返しを設定した登録やテンプレートの編集は家事の購読には現れないため、テンプレートの変化でも組み直す
                .onChange(of: templateContext) {
                    withAnimation {
                        updateHouseboardList(with: houseworkListStore)
                    }
                }
                // 通知から開くと、ダッシュボードを表示しないまま家事タブに着地するため、こちらでも購読を始める
                .task {
                    await startObserving()
                }
                // プランが確定・変化したタイミングで日付リストの選択可能範囲を組み直す
                .task(id: storagePolicy) {
                    rebuildDateList()
                }
        } else {
            // TODO: グループ登録前は利用できない旨の空表示を出す
            ContentUnavailableView(
                .localized("グループの登録または参加を行うと、家事の管理ができるようになります。"),
                systemImage: ""
            )
        }
    }

}

// MARK: - UI定義

private extension HouseworkBoardScreen {

    func board(houseworkListStore: HouseworkListStore) -> some View {
        boardNavigation(houseworkListStore: houseworkListStore)
            .sheet(isPresented: $isPresentingAddHouseworkView) {
                RegisterHouseworkView(
                    dailyHouseworkList: .makeInitialValue(
                        selectedDate: dateList.selectedDate,
                        items: [],
                        calendar: calendar,
                        storagePolicy: storagePolicy
                    ),
                    step: .board
                )
            }
            // TabViewのページの中や、空表示と切り替わる一覧に置くと、完了にした家事が一覧から消えたときに
            // シートを出しているビューごと作り直され、閉じたシートがもう一度出てしまうため、ボード全体に置く
            .sheet(item: $completingItem) { item in
                HouseworkCompleteSheet(item: item, step: .board)
            }
            // モーダルの上ではなく、閉じた後のボードに演出を出す。モーダルを閉じるのを演出で待たせないため
            .sheet(item: $thankingItem, onDismiss: dismissedThanksView) { item in
                HouseworkThanksView(item: item) {
                    hasPendingThanksFeedback = true
                }
            }
            .sheet(item: $addingHelperItem) { item in
                HouseworkAddHelperSheet(item: item, step: .board)
            }
            .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
                router.resolve(.houseworkTemplate)
            }
            .fullScreenCoverOnIOS(
                isPresented: $isShowPaywall,
                onDismiss: { dismissedPaywall() },
                content: { router.resolve(.paywall) }
            )
            .onChange(of: houseworkListStore.items) {
                withAnimation {
                    updateHouseboardList(with: houseworkListStore)
                }
                openPendingHouseworkDetail(store: houseworkListStore)
            }
            // 通知から開く家事は、起動直後だとまだ読み込まれていないため、家事が届くたびに探し直す
            .onChange(of: pendingNotificationRouteStore.pendingRoute, initial: true) {
                openPendingHouseworkDetail(store: houseworkListStore)
            }
            .onChange(of: houseworkListStore.loadState) {
                openPendingHouseworkDetail(store: houseworkListStore)
            }
            .onChange(of: dateList.selectedDate) {
                withAnimation {
                    updateHouseboardList(with: houseworkListStore)
                }
            }
            .thanksFeedback(trigger: thanksFeedbackCount)
            .commonError(content: $commonError)
            .fullScreenLoadingIndicator(loadingState)
            .trackScreenView(.houseworkBoard)
    }

    func boardNavigation(houseworkListStore: HouseworkListStore) -> some View {
        NavigationStack(path: $navigationPath.path) {
            HouseworkBoardView(
                dateList: $dateList,
                selectedHouseworkState: $selectedHouseworkState,
                isSelecting: $isSelecting,
                selectedHouseworkIDs: $selectedHouseworkIDs,
                houseworkBoardList: houseworkBoardList,
                members: members,
                ownUserId: loginContext.account.id,
                loadFailure: loadFailure(of: houseworkListStore),
                onTapRetry: {
                    loadingState.task {
                        await retry()
                    }
                },
                onTapAdd: { isPresentingAddHouseworkView = true },
                onTapItem: { navigationPath.push(.houseworkDetail($0)) },
                onTapComplete: { completingItem = $0 },
                onTapThanks: { item in
                    Task {
                        await sendThanks(to: item, store: houseworkListStore)
                    }
                },
                onTapStorageLimit: { tappedStorageLimitCell() },
                onTapHouseworkTemplate: { isShowHouseworkTemplate = true },
                onTapBulkAction: { action in
                    Task {
                        await performBulk(action, store: houseworkListStore)
                    }
                },
                rowMenu: { item in
                    HouseworkQuickActionMenuContent(
                        item: item,
                        step: .board,
                        canAddHelper: item.canAddHelper(members: members),
                        onSelectComplete: { completingItem = item },
                        onSelectThanks: { thankingItem = item },
                        onSelectAddHelper: { addingHelperItem = item },
                        onError: { commonError = .init(error: $0) }
                    )
                }
            )
            .navigationDestination(for: HouseworkBoardRoute.self) { route in
                navigationHandler(route)
            }
            .environment(\.houseworkBoardNavigationPath, navigationPath)
        }
    }

    @ViewBuilder
    func navigationHandler(_ route: HouseworkBoardRoute) -> some View {
        switch route {
        case let .houseworkDetail(item):
            HouseworkDetailView(item: item)
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkBoardScreen {

    func onAppeare(with store: HouseworkListStore) {
        updateHouseboardList(with: store)
    }

    /// 家事の購読が失敗している場合に、エラー表示に使う内容を返す
    func loadFailure(of store: HouseworkListStore) -> DomainError? {
        guard case let .failed(error) = store.loadState else { return nil }
        return error
    }

    /// 家事とメンバーの購読を始める
    /// - Note: ダッシュボードの表示時にも同じ購読を始めている。どちらも購読中なら何もしないため、
    ///         両方のタブを表示しても購読は重複しない
    func startObserving() async {
        guard let cohabitantId = loginContext.cohabitantId else { return }
        await cohabitantStore.addSnapshotListenerIfNeeded(cohabitantId, ownId: loginContext.account.id)
        await houseworkManager.setupObserver(
            currentTime: now,
            cohabitantId: cohabitantId,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    /// 家事の購読をやり直す
    /// - Note: `HouseworkManager`のリスナーは失敗時に購読が止まるため、リスナーを張り直す
    ///         `setupObserver`の再実行で復帰させる。
    func retry() async {
        guard let cohabitantId = loginContext.cohabitantId else { return }
        await houseworkManager.setupObserver(
            currentTime: now,
            cohabitantId: cohabitantId,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    func rebuildDateList() {
        dateList = .init(
            anchorDate: now,
            selectedDate: dateList.selectedDate,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    func updateHouseboardList(with store: HouseworkListStore) {
        let selectedDate = dateList.selectedDate
        houseworkBoardList = .init(
            dailyList: store.items.value,
            selectedDateTemplate: templateContext.templateOfDay(by: selectedDate, calendar: calendar),
            selectedDate: dateList.selectedDate,
            calendar: calendar,
            storagePolicy: storagePolicy,
            uuidGenerator: { UUID() }
        )
    }

    /// ハートのタップでは、メッセージを書かずにありがとうだけを伝える（コメントがないので通知は送らない）
    func sendThanks(to item: HouseworkBoardItem, store: HouseworkListStore) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            let isFirstThanks = try await store.perform(
                .sendThanks,
                on: item,
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: .board
            )
            if isFirstThanks {
                thanksFeedbackCount += 1
            }
        } catch {
            commonError = .init(error: error)
        }
    }

    func performBulk(_ action: HouseworkQuickAction, store: HouseworkListStore) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        let selection = HouseworkSelection(
            items: houseworkBoardList.items(matching: selectedHouseworkState),
            state: selectedHouseworkState,
            selectedIDs: selectedHouseworkIDs,
            ownUserId: loginContext.account.id
        )
        do {
            let hasSentFirstThanks = try await store.performBulk(
                action,
                on: selection.targets(for: action),
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: .board
            )
            selectedHouseworkIDs = []
            // 何件伝えても演出は1回だけにする
            if hasSentFirstThanks {
                thanksFeedbackCount += 1
            }
        } catch {
            commonError = .init(error: error)
        }
    }

    /// 通知から開く家事が見つかったら、その家事の詳細画面を開く
    /// - Note: 別の画面を開いていても、通知の家事の詳細だけが積まれた状態にする。
    ///         詳細から戻ったときにその家事が見えるよう、ボードもその家事の日付と状態に切り替える。
    ///         シートやフルスクリーンカバーは閉じず、その裏に詳細画面を積む。購入中のペイウォールや入力中の
    ///         シートを通知で勝手に閉じないためで、ダッシュボード側のシートなどはそもそもここから閉じられない
    func openPendingHouseworkDetail(store: HouseworkListStore) {
        guard let item = pendingNotificationRouteStore.takeHouseworkDetailItem(
            in: store.items,
            loadState: store.loadState
        ) else { return }

        isSelecting = false
        dateList.selectDate(item.indexedDate.value, calendar: calendar)
        if HouseworkState.pageableCases.contains(item.state) {
            selectedHouseworkState = item.state
        }
        navigationPath.path = [.houseworkDetail(.init(originalItem: item, isRegistered: true))]
    }

    func dismissedThanksView() {
        guard hasPendingThanksFeedback else { return }
        hasPendingThanksFeedback = false
        thanksFeedbackCount += 1
    }

    func tappedStorageLimitCell() {
        analyticsClient.log(.paywall(.shown(step: .boardStorageLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(step: .boardStorageLimit, isPremium: subscriptionStore.isPremium)))
    }

}
