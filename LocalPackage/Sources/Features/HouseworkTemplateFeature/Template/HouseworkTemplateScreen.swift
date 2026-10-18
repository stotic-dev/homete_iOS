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
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkTemplateListStore.self) var houseworkTemplateListStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.isAdsEnabled) var isAdsEnabled
    @Environment(\.cohabitantMembers) var members
    @Environment(\.routeResolver) var router

    @CommonError var commonErrorContent

    @State var templateEditStore: HouseworkTemplateEditStore
    /// 初めて開いたときに出すチュートリアル
    @State var tutorialStore: ScreenTutorialStore<HouseworkTemplateTutorialStep>
    @State var initialDraft: HouseworkTemplateDraft?
    @State var editingDraft: HouseworkTemplateDraft = .init()
    @State var editorContext: TemplateEditorContext = .init(currentActiveEditors: [], currentTemplateVersion: .zero)
    @State var isShowPaywall = false

    public static func make() -> some View {
        DependenciesInjectLayer {
            HouseworkTemplateScreen(
                templateEditStore: .init(houseworkTemplateClient: $0.houseworkTemplateClient),
                tutorialStore: .init(stateClient: $0.screenTutorialStateClient, analyticsClient: $0.analyticsClient)
            )
        }
    }

    public var body: some View {
        ZStack {
            templateContent()
                // 後ろに隠れた本番の画面のUIが、チュートリアルの画面と同じ識別子で位置を伝えないようにする
                .excludedFromTutorialSpotlight()
            if let step = tutorialStore.currentStep {
                HouseworkTemplateTutorialView(step: step)
            }
        }
        .tutorialSpotlight(
            isPresented: tutorialStore.currentStep != nil,
            targets: tutorialStore.currentStep.map(spotlightTargets) ?? []
        ) {
            tutorialCard()
        }
        .animation(.default, value: tutorialStore.currentStep)
        .commonError(content: $commonErrorContent)
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
        .task(id: tutorialPrerequisiteLoadStates) {
            await startTutorialIfNeeded()
        }
        .task {
            await onAppear()
        }
        .task {
            await observeEditorExpiry()
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
        .onChange(of: houseworkTemplateListStore.selectedTemplateId) { oldValue, newValue in
            Task {
                await onChangeSelectedTemplateId(oldValue: oldValue, newValue: newValue)
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkTemplateScreen {

    func templateContent() -> some View {
        NavigationStack {
            HouseworkTemplateView(
                initialDraft: $initialDraft,
                draft: $editingDraft,
                editorContext: $editorContext,
                isShowAd: AdDisplayPolicy.shouldShowAds(
                    isPremium: subscriptionStore.isPremium,
                    isEnabled: isAdsEnabled
                ),
                memoLimitPolicy: .init(isPremium: subscriptionStore.isPremium),
                loadFailure: loadFailure,
                onTapRemoveAdsLink: { tappedRemoveAdsLink() },
                onRetry: { await retry() }
            )
        }
        .environment(templateEditStore)
    }

    @ViewBuilder
    func tutorialCard() -> some View {
        if let step = tutorialStore.currentStep {
            HouseworkTemplateTutorialCard(
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

    func spotlightTargets(_ step: HouseworkTemplateTutorialStep) -> [TutorialSpotlightID] {
        switch step {
        case .create:
            [.houseworkTemplateCreateButton]

        case .addItem:
            [.houseworkTemplateAddButton]

        case .autoPlacement:
            // 「毎月」のセクションは画面の下にあり、説明のカードを置く空きが無くなるため切り抜かない
            [.houseworkTemplateFirstDaySection]

        case .save:
            [.houseworkTemplateNavigationBar]
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateScreen {

    /// チュートリアルを出せるかを決める読み込みの状態。変わるたびに出せるかを判断し直す
    var tutorialPrerequisiteLoadStates: [ListenerLoadState] {
        [houseworkTemplateListStore.loadState, templateEditStore.loadState]
    }

    /// テンプレートの有無が分かってから、チュートリアルを出す
    /// - Note: 作成済みなら作成のステップは要らないので除く。
    ///         読み込みが終わるまでは`selectedTemplateId`がnilでも「テンプレートが無い」とは限らないため待つ。
    ///         作成済みなら編集の準備が済むまで待つ。準備に失敗するとエラーの表示に切り替わり、
    ///         その上でチュートリアルを最後まで見ると、使えない画面のまま見たことになってしまうため
    func startTutorialIfNeeded() async {
        guard houseworkTemplateListStore.loadState == .loaded else { return }

        let hasTemplate = houseworkTemplateListStore.selectedTemplateId != nil
        guard !hasTemplate || templateEditStore.loadState == .loaded else { return }

        await tutorialStore.startIfNeeded(skipping: hasTemplate ? [.create] : [])
    }

    func tappedRemoveAdsLink() {
        analyticsClient.log(.advertisement(step: .template))
        analyticsClient.log(.paywall(.shown(step: .templateAd)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(step: .templateAd, isPremium: subscriptionStore.isPremium)))
    }

    func onAppear() async {
        // currentVersionで変更検知するためテンプレートの変更監視を止める
        await houseworkTemplateListStore.stopObservingItems()

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
            let initialDraftOnAppear = HouseworkTemplateDraft.make(
                houseworkTemplateListStore.selectedDays,
                monthlyItems: houseworkTemplateListStore.monthlyItems
            )
            editingDraft = initialDraftOnAppear
            initialDraft = initialDraftOnAppear
        } catch {
            // 編集状態の監視・登録ができないと編集機能が成立しないので、
            // Storeが持つloadStateを根拠にエラー表示へ倒し、この画面のままリトライできるようにする
            print("failed to start editing housework template: \(error)")
        }
    }

    /// テンプレートの初回ロードが失敗している場合に、エラー表示に使う内容を返す
    var loadFailure: DomainError? {
        for state in [houseworkTemplateListStore.loadState, templateEditStore.loadState] {
            if case let .failed(error) = state {
                return error
            }
        }
        return nil
    }

    /// テンプレートの初回ロードをやり直す
    /// - Note: 失敗した層から順にやり直す（一覧の取得から失敗している場合はconfigureから）。
    func retry() async {
        guard let cohabitantId = account.cohabitantId else { return }

        // テンプレート一覧のロード自体が失敗していた場合は、そこからやり直す
        if case .failed = houseworkTemplateListStore.loadState {
            try? await houseworkTemplateListStore.configure(cohabitantId: cohabitantId)
        }

        if let templateId = houseworkTemplateListStore.selectedTemplateId {
            await templateEditStore.stopEditing(
                templateId: templateId,
                cohabitantId: cohabitantId,
                userId: account.id
            )
        }
        await onAppear()
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
        await houseworkTemplateListStore.startObservingItems(
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

    /// editorsのスナップショットに変化が無くても、経過時間で編集者バッジを再評価する
    /// （相手のアプリがクラッシュ等でpresence更新が止まった場合、Firestore側のTTL削除（最大24時間）を待たずに表示から外すため）
    func observeEditorExpiry() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            editorContext = editorContext.applyEditors(
                editors: templateEditStore.editors,
                members: members,
                now: .now
            )
        }
    }

    func onChangeTemplateVersion() async {
        // ローカルで保持しているテンプレートバージョンよりも大きいバージョンの場合に、コンフリクトが発生したとみなす
        guard editorContext.currentTemplateVersion < templateEditStore.currentVersion,
              let templateId = houseworkTemplateListStore.selectedTemplateId,
              let cohabitantId = account.cohabitantId else { return }

        await loadCurrentTemplate(templateId: templateId, cohabitantId: cohabitantId)
    }

    func onChangeSelectedTemplateId(oldValue: String?, newValue: String?) async {
        // テンプレート画面内でテンプレートがない状態からテンプレートが作成されたことを検知したら、
        // 現在のテンプレートの内容をロードする
        guard oldValue == nil,
              let newValue,
              let cohabitantId = account.cohabitantId else { return }

        await loadCurrentTemplate(templateId: newValue, cohabitantId: cohabitantId)
    }

    func loadCurrentTemplate(templateId: String, cohabitantId: String) async {
        do {
            // バージョンが変わったらテンプレートの内容を再ロードする
            try await houseworkTemplateListStore.loadDays(templateId: templateId, cohabitantId: cohabitantId)
            await houseworkTemplateListStore.loadMonthlyItems(templateId: templateId, cohabitantId: cohabitantId)
            // 未保存の変更が残っている場合はコンフリクトアラートで解決されるまでバージョンを進めない
            // （先にバージョンを進めてしまうと、アラートを「キャンセル」した後の保存で楽観ロックが素通りしてしまうため）
            let hasUnresolvedConflict = initialDraft?.hasUnsavedChanges(comparedTo: editingDraft) ?? false
            let latestDraft = HouseworkTemplateDraft.make(
                houseworkTemplateListStore.selectedDays,
                monthlyItems: houseworkTemplateListStore.monthlyItems
            )
            initialDraft = latestDraft
            if !hasUnresolvedConflict {
                // 未保存の変更が無い場合は編集中の内容も最新化する
                // （editingDraftを更新しないとinitialDraftとの差分検知で誤ってコンフリクトアラートが表示されてしまうため）
                editingDraft = latestDraft
                editorContext = editorContext.applyEditors(templateEditStore.currentVersion)
            }
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

}
