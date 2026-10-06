//
//  AppTabView.swift
//

import ContributionFeature
import HomeFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import HouseworkTemplateFeature
import SwiftUI

struct AppTabView: View {

    @Environment(\.appDependencies) var appDependencies
    @Environment(\.loginContext) var loginContext
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(RegistrationTutorialStore.self) var registrationTutorialStore
    @Environment(\.routeResolver) var router

    @State var contributionStore: ContributionStore?
    @State var houseworkListStore: HouseworkListStore?
    @State var houseworkTemplateListStore: HouseworkTemplateListStore?
    @State var frequentHouseworkStore: FrequentHouseworkStore?
    @State var type: TabType = .dashboard

    var handler: Binding<TabType> {
        Binding(
            get: { type },
            set: {
                if $0 == type {
                    NotificationCenter.default.post(
                        name: .onTapAppAlreadySelectedTabItem,
                        object: nil,
                        userInfo: OnTapAppAlreadySelectedTabItemContext.makeUserInfo(from: $0)
                    )
                }
                type = $0
            }
        )
    }

    /// 招待リンクの参加画面を表示するかどうか
    /// - Note: 閉じられたら未処理のトークンを破棄して、同じ招待で再表示されないようにする
    var isPresentingCohabitantJoin: Binding<Bool> {
        Binding(
            get: { pendingInvitationStore.pendingToken != nil },
            set: { isPresenting in
                if !isPresenting {
                    pendingInvitationStore.clear()
                }
            }
        )
    }

    var body: some View {
        tabView()
            // シートやフルスクリーンカバーより奥に描かれるため、登録完了の画面や招待リンクの参加画面が
            // 出ている間は隠れ、閉じられてから見えるようになる
            .tutorialSpotlight(
                isPresented: registrationTutorialStore.currentStep != nil,
                targets: registrationTutorialStore.currentStep.map(spotlightTargets) ?? [],
                cardPlacement: registrationTutorialStore.currentStep.map(cardPlacement) ?? .automatic
            ) {
                registrationTutorialCard()
            }
            .animation(.default, value: registrationTutorialStore.currentStep)
            // ログアウトをまたいでこの画面が作り直されたときも、表示中のステップにタブを合わせる
            .onChange(of: registrationTutorialStore.currentStep, initial: true) {
                switchTabForTutorial(to: registrationTutorialStore.currentStep)
            }
            .fullScreenCoverOnIOS(isPresented: isPresentingCohabitantJoin) {
                if let token = pendingInvitationStore.pendingToken {
                    router.resolve(.cohabitantJoin(token: token))
                }
            }
            // 起動時とグループ切り替え時で必要な準備が同じなので、cohabitantIdをidにして同じ処理に寄せる
            // （onChangeで分けると、参加直後にテンプレートの購読開始が漏れる）
            .task(id: loginContext.cohabitantId) {
                await onChangeCohabitant()
            }
            .task {
                await registrationTutorialStore.restoreIfNeeded(hasCohabitant: loginContext.hasCohabitant)
            }
            .onChange(of: loginContext.cohabitantId) { oldValue, newValue in
                Task {
                    await registrationTutorialStore.didChangeCohabitant(from: oldValue, to: newValue)
                }
            }
            .environment(\.cohabitantMembers, cohabitantStore.members)
            .environment(
                \.houseworkTemplateContext,
                houseworkTemplateListStore?.context ?? .init(metadata: nil, houseworkTemplate: [])
            )
            .environment(
                \.houseworkStoragePolicy,
                HouseworkStoragePolicy(isPremium: subscriptionStore.isPremium)
            )
            .environment(
                \.frequentHouseworkContext,
                frequentHouseworkStore?.context ?? .init()
            )
            .environment(frequentHouseworkStore)
    }

}

// MARK: UI定義

private extension AppTabView {

    func tabView() -> some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: handler) {
                    Tab(
                        "ダッシュボード",
                        systemImage: "list.bullet.clipboard.fill",
                        value: .dashboard
                    ) {
                        homeScreen
                    }
                    Tab(
                        "家事",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise",
                        value: .homework
                    ) {
                        houseworkBoardScreen
                    }
                }
            } else {
                TabView(selection: handler) {
                    homeScreen
                        .tag(TabType.dashboard)
                        .tabItem {
                            Label(
                                "ダッシュボード",
                                systemImage: "list.bullet.clipboard.fill"
                            )
                        }
                    houseworkBoardScreen
                        .tag(TabType.homework)
                        .tabItem {
                            Label(
                                "家事",
                                systemImage: "person.2.arrow.trianglehead.counterclockwise"
                            )
                        }
                }
            }
        }
    }

    @ViewBuilder
    func registrationTutorialCard() -> some View {
        if let step = registrationTutorialStore.currentStep {
            RegistrationTutorialCard(
                step: step,
                onTapNext: {
                    Task {
                        await registrationTutorialStore.next(from: step)
                    }
                },
                onTapBack: {
                    registrationTutorialStore.back(from: step)
                },
                onTapClose: {
                    Task {
                        await registrationTutorialStore.close()
                    }
                }
            )
        }
    }

    // チュートリアルの間は、サンプルの家事を渡した同じUIを本番の画面に重ねて出す。
    // 本番の画面は作り直さずに残し、チュートリアルを終えたらそのまま戻れるようにする

    var homeScreen: some View {
        HomeView.make(
            contributionStore: contributionStore,
            houseworkTemplateListStore: houseworkTemplateListStore,
            houseworkListStore: houseworkListStore
        )
        .excludedFromTutorialSpotlight()
        .overlay {
            if registrationTutorialStore.currentStep == .dashboard {
                DashboardTutorialView(now: now)
                    // カードをタブバーに重ねないよう、タブの中の範囲に置く
                    .tutorialSpotlightCardArea()
                    .background(.background)
            }
        }
    }

    var houseworkBoardScreen: some View {
        HouseworkBoardScreen.make(
            houseworkListStore: houseworkListStore,
            houseworkTemplateListStore: houseworkTemplateListStore
        )
        .excludedFromTutorialSpotlight()
        .overlay {
            if let page = registrationTutorialStore.currentStep.flatMap(tutorialHouseworkPage) {
                HouseworkBoardTutorialView(page: page, now: now)
                    // カードをタブバーに重ねないよう、タブの中の範囲に置く
                    .tutorialSpotlightCardArea()
                    .background(.background)
            }
        }
    }

}

// MARK: チュートリアルの見せ方

private extension AppTabView {

    /// ステップごとに切り抜くUI
    /// - Note: タブバーの項目は位置を取得できず切り抜けないため、カードの文言で場所を伝える
    func spotlightTargets(_ step: RegistrationTutorialStep) -> [TutorialSpotlightID] {
        switch step {
        case .dashboard:
            [.dashboardTodaySummary]

        case .housework:
            [.houseworkAddButton]

        case .houseworkComplete:
            [.houseworkIncompleteRow]

        case .thanks:
            [.houseworkThanksButton]

        case .bulkAction:
            [.houseworkSelectButton]

        case .houseworkTemplate:
            [.houseworkTemplateButton]
        }
    }

    /// ステップごとの説明のカードの置き場所
    func cardPlacement(_ step: RegistrationTutorialStep) -> TutorialSpotlightCardPlacement {
        switch step {
        case .dashboard:
            // 今日の家事サマリーは縦に長く、空きの広い上に置くと説明している達成率に重なるため、下に置く
            .bottom

        case .housework, .houseworkComplete, .thanks, .bulkAction, .houseworkTemplate:
            .automatic
        }
    }

    /// 家事ボードで説明するステップで、表示する一覧
    func tutorialHouseworkPage(_ step: RegistrationTutorialStep) -> HouseworkState? {
        switch step {
        case .dashboard:
            nil

        case .housework, .houseworkComplete:
            .incomplete

        case .thanks, .bulkAction, .houseworkTemplate:
            // ありがとうのハートは完了の一覧にある。それ以降の説明ではそのまま一覧を動かさない
            .completed
        }
    }

}

// MARK: プレゼンテーションロジック

private extension AppTabView {

    /// チュートリアルの説明に合わせてタブを切り替え、終わったらダッシュボードに戻す
    func switchTabForTutorial(to newStep: RegistrationTutorialStep?) {
        guard let newStep else {
            type = .dashboard
            return
        }
        type = tutorialHouseworkPage(newStep) == nil ? .dashboard : .homework
    }

    /// 所属グループが決まった/変わったときに、そのグループ用のストアを組み直す
    func onChangeCohabitant() async {
        // 作り直す前に、前のグループのリスナーを解除しておく
        await frequentHouseworkStore?.stopObserving()
        setupStore()
        await startObserveFrequentHouseworkIfNeeded()
        await startObserveTemplateIfNeeded()
    }

}

private extension AppTabView {

    func setupStore() {
        guard loginContext.hasCohabitant else {
            contributionStore = nil
            frequentHouseworkStore = nil
            return
        }
        contributionStore = .init(
            houseworkManager: appDependencies.houseworkManager,
            calendar: calendar
        )
        houseworkListStore = .init(
            houseworkClient: appDependencies.houseworkClient,
            cohabitantPushNotificationClient: appDependencies.cohabitantPushNotificationClient,
            houseworkManager: appDependencies.houseworkManager,
            analyticsClient: appDependencies.analyticsClient,
            dailyCompletionReminderUseCase: appDependencies.dailyCompletionReminderUseCase,
            calendar: calendar
        )
        houseworkTemplateListStore = .init(
            houseworkTemplateClient: appDependencies.houseworkTemplateClient,
            analyticsClient: appDependencies.analyticsClient
        )
        frequentHouseworkStore = .init(
            frequentHouseworkClient: appDependencies.frequentHouseworkClient,
            analyticsClient: appDependencies.analyticsClient
        )
    }

    func startObserveFrequentHouseworkIfNeeded() async {
        guard let store = frequentHouseworkStore,
              let cohabitantId = loginContext.cohabitantId else { return }

        await store.startObserving(cohabitantId: cohabitantId)
    }

    func startObserveTemplateIfNeeded() async {
        guard let store = houseworkTemplateListStore,
              let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await store.configure(cohabitantId: cohabitantId)
        } catch {
            // 失敗内容はStoreの`loadState`に記録され、テンプレート画面でリトライ導線として表示される
            print("failed to configure housework template store: \(error)")
        }
    }

}

#Preview {
    AppTabView()
        .environment(AccountStore())
        .environment(AccountAuthStore())
        .environment(CohabitantStore())
        .environment(PendingInvitationStore())
        .environment(RegistrationTutorialStore())
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
