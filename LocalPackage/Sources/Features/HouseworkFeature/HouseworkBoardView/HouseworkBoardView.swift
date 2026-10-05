//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkBoardView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.routeResolver) var router
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(PendingNotificationRouteStore.self) var pendingNotificationRouteStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext) var loginContext

    @Binding var houseworkBoardList: HouseworkBoardList
    @Binding var dateList: HouseworkDateList

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

    /// 家事の購読に失敗している場合のエラー内容
    let loadFailure: DomainError?
    let onUpdateHouseboardList: () -> Void
    let onRetry: () async -> Void

    var body: some View {
        // 一覧をタブバーの裏まで伸ばすと、一覧側からは下端のセーフエリアが見えなくなる。
        // 伸ばす前のここで測っておき、一覧の終端の余白として足し直す
        GeometryReader { proxy in
            boardBody(bottomSafeAreaInset: proxy.safeAreaInsets.bottom)
        }
    }

    func boardBody(bottomSafeAreaInset: CGFloat) -> some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                if let loadFailure {
                    LoadErrorView(error: loadFailure) {
                        loadingState.task {
                            await onRetry()
                        }
                    }
                } else {
                    boardContent(bottomSafeAreaInset: bottomSafeAreaInset)
                }
            }
            // 一覧の下に追加ボタンの分の余白を作り、終端までスクロールしても最後の家事行と重ならないようにする。
            // `overlay`で浮かせると一覧の上に乗るだけで余白ができず、行の右側（ポイント）が隠れてしまう
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                if loadFailure == nil {
                    AddHouseworkButton {
                        isPresentingAddHouseworkView = true
                    }
                    .padding(.trailing, .space24)
                    .padding(.bottom, .space24)
                }
            }
            .navigationDestination(for: HouseworkBoardRoute.self) { route in
                navigationHandler(route)
            }
            .softTopScrollEdgeEffect()
            .leadingToolbarItem {
                if isSelecting {
                    cancelSelectingButton()
                }
            }
            .trailingToolbarItem {
                if isSelecting {
                    bulkActionContent()
                } else {
                    defaultToolbarContent()
                }
            }
            .environment(\.houseworkBoardNavigationPath, navigationPath)
        }
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
                onUpdateHouseboardList()
            }
            openPendingHouseworkDetail()
        }
        // 通知から開く家事は、起動直後だとまだ読み込まれていないため、家事が届くたびに探し直す
        .onChange(of: pendingNotificationRouteStore.pendingRoute, initial: true) {
            openPendingHouseworkDetail()
        }
        .onChange(of: houseworkListStore.loadState) {
            openPendingHouseworkDetail()
        }
        .onChange(of: dateList.selectedDate) {
            withAnimation {
                onUpdateHouseboardList()
            }
        }
        .onChange(of: selectedHouseworkState) {
            withAnimation {
                isSelecting = false
            }
        }
        // 選択モードの出入りで選択を持ち越さない（タブの切り替えも選択モードの終了を経由する）
        .onChange(of: isSelecting) {
            selectedHouseworkIDs = []
        }
        .thanksFeedback(trigger: thanksFeedbackCount)
        .commonError(content: $commonError)
        .fullScreenLoadingIndicator(loadingState)
        .trackScreenView(.houseworkBoard)
    }

}

private extension HouseworkBoardView {

    /// 表示中のタブと選択状態から組み立てた、複数選択の判定
    var selection: HouseworkSelection {
        .init(
            items: houseworkBoardList.items(matching: selectedHouseworkState),
            state: selectedHouseworkState,
            selectedIDs: selectedHouseworkIDs,
            ownUserId: loginContext.account.id
        )
    }

    func boardContent(bottomSafeAreaInset: CGFloat) -> some View {
        VStack(spacing: .space16) {
            HouseworkDateHeaderContent(dateList: $dateList) {
                tappedStorageLimitCell()
            }
            VStack(spacing: .space16) {
                HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                TabView(selection: $selectedHouseworkState) {
                    ForEach(HouseworkState.pageableCases) { state in
                        HouseworkBoardListContent(
                            houseworkListStore: houseworkListStore,
                            state: state,
                            list: houseworkBoardList,
                            memberList: members,
                            bottomContentInset: bottomSafeAreaInset,
                            selectedHouseworkState: $selectedHouseworkState,
                            isSelecting: $isSelecting,
                            selectedIDs: $selectedHouseworkIDs,
                            onCreateTapped: { isPresentingAddHouseworkView = true },
                            onSelectComplete: { completingItem = $0 },
                            onSelectThanks: { thankingItem = $0 },
                            onSelectAddHelper: { addingHelperItem = $0 },
                            onSentFirstThanks: { thanksFeedbackCount += 1 }
                        )
                        .tag(state)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                // 一覧をタブバーの裏まで伸ばし、スクロールした中身がタブバー越しに透けて見えるようにする
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.horizontal, .space16)
        }
    }

    /// 通知から開く家事が見つかったら、その家事の詳細画面を開く
    /// - Note: 別の画面を開いていても、通知の家事の詳細だけが積まれた状態にする
    func openPendingHouseworkDetail() {
        guard let item = pendingNotificationRouteStore.takeHouseworkDetailItem(
            in: houseworkListStore.items,
            loadState: houseworkListStore.loadState
        ) else { return }

        isSelecting = false
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

    /// 選択モードでないときのナビゲーションバー右側（選択モードへの入口とテンプレート）
    func defaultToolbarContent() -> some View {
        HStack(spacing: .space16) {
            Button("選択") {
                withAnimation {
                    isSelecting = true
                }
            }
            NavigationBarButton(label: .houseworkTemplate) {
                isShowHouseworkTemplate = true
            }
        }
    }

    /// 選択モードを抜けるボタン。左上に置いて、選択モードに入っていること自体を分かりやすくする
    func cancelSelectingButton() -> some View {
        NavigationBarButton(label: .close) {
            withAnimation {
                isSelecting = false
            }
        }
        .accessibilityLabel("選択をやめる")
    }

    func bulkActionContent() -> some View {
        HouseworkBulkActionToolbarContent(
            actions: selection.availableActions,
            isEnabled: !selection.isEmpty,
            onTap: { action in
                Task {
                    await performBulk(action)
                }
            }
        )
    }

    func performBulk(_ action: HouseworkQuickAction) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            let hasSentFirstThanks = try await houseworkListStore.performBulk(
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

    @ViewBuilder
    func navigationHandler(_ route: HouseworkBoardRoute) -> some View {
        switch route {
        case let .houseworkDetail(item):
            HouseworkDetailView(item: item)
        }
    }

}

#if DEBUG
#Preview {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            title: "洗濯",
            point: 20
        ),
    ])
    HouseworkBoardView(
        houseworkBoardList: .constant(list),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        loadFailure: nil,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
    .environment(PendingNotificationRouteStore())
    .environment(SubscriptionStore())
}

#Preview("HouseworkBoardView_選択モード") {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            id: "1",
            title: "洗濯",
            point: 20
        ),
        .makeForPreview(
            id: "2",
            title: "掃除",
            point: 100
        ),
    ])
    HouseworkBoardView(
        houseworkBoardList: .constant(list),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        isSelecting: true,
        selectedHouseworkIDs: ["1"],
        loadFailure: nil,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
    .environment(PendingNotificationRouteStore())
    .environment(SubscriptionStore())
}

#Preview("HouseworkBoardView_読み込みエラー") {
    HouseworkBoardView(
        houseworkBoardList: .constant(.init(items: [])),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        loadFailure: .noNetwork,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
    .environment(PendingNotificationRouteStore())
    .environment(SubscriptionStore())
}

#Preview("HouseworkBoardView_家事が多い") {
    let list = HouseworkBoardList(items: (1 ... 10).map { index in
        HouseworkBoardItem.makeForPreview(
            id: "\(index)",
            title: "家事\(index)",
            point: index * 10
        )
    })
    HouseworkBoardView(
        houseworkBoardList: .constant(list),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        loadFailure: nil,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
    .environment(PendingNotificationRouteStore())
    .environment(SubscriptionStore())
}
#endif
