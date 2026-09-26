//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import ContributionFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

public struct HomeView: View {

    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.appDependencies.notificationPermissionUseCase) var notificationPermissionUseCase
    @Environment(\.appDependencies.adsSetupUseCase) var adsSetupUseCase
    @Environment(\.appDependencies.pasteboardClient) var pasteboardClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.scenePhase) var scenePhase
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(CohabitantStore.self) var cohabitantStore

    @State var isShowCohabitantRegistrationModal = false
    @State var pasteboardInvitationStore: PasteboardInvitationStore?
    @State var isShowSetting = false
    @State var registeredContentNavigationPath = AppNavigationPath<RegisteredContentRoute>()
    let contributionStore: ContributionStore?
    let houseworkTemplateListStore: HouseworkTemplateListStore?
    let houseworkListStore: HouseworkListStore?

    public var body: some View {
        NavigationStack(path: $registeredContentNavigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    if loginContext.hasCohabitant,
                       let contributionStore,
                       let houseworkListStore,
                       let houseworkTemplateListStore {
                        registeredContent(
                            contributionStore: contributionStore,
                            houseworkTemplateListStore: houseworkTemplateListStore,
                            houseworkListStore: houseworkListStore
                        )
                    } else if !loginContext.hasCohabitant {
                        notRegisteredContent()
                    }
                }
                .fullScreenCoverOnIOS(isPresented: $isShowCohabitantRegistrationModal) {
                    router.resolve(.cohabitantRegistration)
                }
                .softTopScrollEdgeEffect()
                .trailingToolbarItem {
                    NavigationBarButton(label: .settings) {
                        isShowSetting = true
                    }
                }
                .sheet(isPresented: $isShowSetting) {
                    router.resolve(.setting)
                }
            }
            .environment(\.registeredContentNavigationPath, registeredContentNavigationPath)
        }
        .task {
            await onAppear()
        }
    }

}

public extension HomeView {

    static func make(
        contributionStore: ContributionStore?,
        houseworkTemplateListStore: HouseworkTemplateListStore?,
        houseworkListStore: HouseworkListStore?
    ) -> some View {
        HomeView(
            contributionStore: contributionStore,
            houseworkTemplateListStore: houseworkTemplateListStore,
            houseworkListStore: houseworkListStore
        )
    }

}

private extension HomeView {

    func registeredContent(
        contributionStore: ContributionStore,
        houseworkTemplateListStore: HouseworkTemplateListStore,
        houseworkListStore: HouseworkListStore
    ) -> some View {
        RegisteredContent(onRetry: {
            await didAppearRegisteredContent()
        })
        .task {
            await didAppearRegisteredContent()
        }
        .sheet(isPresented: $isShowSetting) {
            router.resolve(.setting)
        }
        .environment(contributionStore)
        .environment(houseworkTemplateListStore)
        .environment(houseworkListStore)
    }

    func notRegisteredContent() -> some View {
        NotRegisteredContent(
            isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal,
            pasteboardInvitationState: pasteboardInvitationStore?.state ?? .idle,
            onTapCheckPasteboard: {
                Task {
                    await pasteboardInvitationStore?.readInvitation()
                }
            }
        )
        .task {
            await didAppearNotRegisteredContent()
        }
        // 着地ページでコピーしてからApp Store経由で戻ってくるため、復帰のたびにクリップボードを確認し直す
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task {
                await pasteboardInvitationStore?.checkIfNeeded()
            }
        }
    }

}

// MARK: プレゼンテーションロジック

private extension HomeView {

    /// ホーム着地のたびに、権限まわりのリクエストを順番に行う
    /// - Note: オンボーディングを途中で抜けたユーザーにも権限を案内するため、着地のたびに実行する。
    ///         ただし通知権限はオンボーディングで案内済みなら`requestIfNeeded`側でスキップされる（直前のスキップ操作を尊重するため）。
    ///         いずれもOSの仕様上、決定済みの場合はダイアログが出ずに即座に完了する。
    ///         ダイアログが重ならないよう、通知権限 → 広告の同意（ATT含む）の順に直列で実行する
    func onAppear() async {
        await notificationPermissionUseCase.requestIfNeeded()
        await adsSetupUseCase.setup()
    }

    func didAppearRegisteredContent() async {
        guard let cohabitantId = loginContext.account.cohabitantId else {
            // パートナー登録完了後にcohabitantIdが無いケースは想定外なので表明としてassertionFailureを行う
            assertionFailure("Required param is nil(cohabitantId)")
            return
        }
        await cohabitantStore.addSnapshotListenerIfNeeded(cohabitantId, ownId: loginContext.account.id)
        await houseworkManager.setupObserver(
            currentTime: now,
            cohabitantId: cohabitantId,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
    }

    func didAppearNotRegisteredContent() async {
        // グループに所属していない間は、脱退前のグループの購読とメンバーを残さない
        await cohabitantStore.clear()
        if pasteboardInvitationStore == nil {
            pasteboardInvitationStore = .init(
                pasteboardClient: pasteboardClient,
                analyticsClient: analyticsClient,
                pendingInvitationStore: pendingInvitationStore
            )
        }
        await pasteboardInvitationStore?.checkIfNeeded()
    }

}
