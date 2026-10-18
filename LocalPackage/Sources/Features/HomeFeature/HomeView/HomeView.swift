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
    @Environment(SentInvitationStore.self) var sentInvitationStore
    @Environment(CohabitantStore.self) var cohabitantStore

    @State var isShowCohabitantRegistrationModal = false
    @State var pasteboardInvitationStore: PasteboardInvitationStore?
    @State var isShowSetting = false
    @State var isShowAccountLink = false
    /// 「もう一度送る」で共有シートに出している招待
    @State var resendingInvitation: CohabitantInvitation?
    /// 共有シートで共有を完了した。共有シートを閉じた後に、匿名ならApple連携を求める
    @State var hasSharedInvitation = false
    /// パートナー登録の画面を開いたときに送ってあった招待。登録画面の中から招待を送ったかを見分けるために使う
    @State var sentInvitationTokenBeforeRegistration: String?
    @State var registeredContentNavigationPath = AppNavigationPath<RegisteredContentRoute>()
    let contributionStore: ContributionStore?
    let houseworkTemplateListStore: HouseworkTemplateListStore?
    let houseworkListStore: HouseworkListStore?
    let encouragementCommentStore: EncouragementCommentStore?

    public var body: some View {
        NavigationStack(path: $registeredContentNavigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    if loginContext.hasCohabitant,
                       let contributionStore,
                       let houseworkListStore,
                       let houseworkTemplateListStore,
                       let encouragementCommentStore {
                        registeredContent(
                            contributionStore: contributionStore,
                            houseworkTemplateListStore: houseworkTemplateListStore,
                            houseworkListStore: houseworkListStore,
                            encouragementCommentStore: encouragementCommentStore
                        )
                    } else if !loginContext.hasCohabitant {
                        notRegisteredContent()
                    }
                }
                .fullScreenCoverOnIOS(
                    isPresented: $isShowCohabitantRegistrationModal,
                    onDismiss: { dismissedCohabitantRegistration() },
                    content: { router.resolve(.cohabitantRegistration) }
                )
                .homeNavigationBar {
                    isShowSetting = true
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
        houseworkListStore: HouseworkListStore?,
        encouragementCommentStore: EncouragementCommentStore?
    ) -> some View {
        HomeView(
            contributionStore: contributionStore,
            houseworkTemplateListStore: houseworkTemplateListStore,
            houseworkListStore: houseworkListStore,
            encouragementCommentStore: encouragementCommentStore
        )
    }

}

private extension HomeView {

    func registeredContent(
        contributionStore: ContributionStore,
        houseworkTemplateListStore: HouseworkTemplateListStore,
        houseworkListStore: HouseworkListStore,
        encouragementCommentStore: EncouragementCommentStore
    ) -> some View {
        RegisteredContent(onRetry: {
            await didAppearRegisteredContent()
        })
        .task {
            await didAppearRegisteredContent()
        }
        // 設定から開く画面（家事テンプレートなど）がStoreを使うため、Storeの注入より内側で出す
        .sheet(isPresented: $isShowSetting) {
            router.resolve(.setting)
        }
        .environment(contributionStore)
        .environment(houseworkTemplateListStore)
        .environment(houseworkListStore)
        .environment(encouragementCommentStore)
    }

    func notRegisteredContent() -> some View {
        NotRegisteredContent(
            isAnonymous: loginContext.isAnonymous,
            isWaitingForPartner: waitingInvitation != nil,
            pasteboardInvitationState: pasteboardInvitationStore?.state ?? .idle,
            onTapRegisterPartner: { tappedRegisterPartner() },
            onTapResendInvitation: { tappedResendInvitation() },
            onTapLinkAccount: { isShowAccountLink = true },
            onTapCheckPasteboard: {
                Task {
                    await pasteboardInvitationStore?.readInvitation()
                }
            }
        )
        .task {
            await didAppearNotRegisteredContent()
        }
        .sheet(isPresented: $isShowSetting) {
            router.resolve(.setting)
        }
        .sheet(
            item: $resendingInvitation,
            onDismiss: { dismissedShareSheet() },
            content: { invitation in
                if let url = invitation.url {
                    ShareSheet(text: CohabitantInvitation.shareMessage, url: url) { isCompleted in
                        completedShareSheet(invitation, isCompleted: isCompleted)
                    }
                }
            }
        )
        .sheet(isPresented: $isShowAccountLink) {
            router.resolve(.accountLink(entry: .todo))
        }
        // 着地ページでコピーしてからApp Store経由で戻ってくるため、復帰のたびにクリップボードを確認し直す
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task {
                await pasteboardInvitationStore?.checkIfNeeded()
            }
        }
        .trackScreenView(.dashboardNotRegistered)
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

    /// 送った招待のうち、有効期限内で相手の参加を待っているもの
    var waitingInvitation: CohabitantInvitation? {
        sentInvitationStore.waitingInvitation(accountId: loginContext.account.id, now: now)
    }

    func tappedRegisterPartner() {
        sentInvitationTokenBeforeRegistration = sentInvitationStore.sentInvitation?.token
        isShowCohabitantRegistrationModal = true
    }

    /// 匿名のまま招待を送ると、相手が参加した時点でApple連携の画面から先に進めなくなる。
    /// 登録画面の中から招待を送ったら、その場で連携してもらう
    /// - Note: P2Pでの登録を終えた場合はグループに入り、起動状態がApple連携を求める画面に切り替わるため、ここでは出さない
    func dismissedCohabitantRegistration() {
        let hasSentInvitation = sentInvitationStore.sentInvitation?.token != sentInvitationTokenBeforeRegistration
        guard loginContext.isAnonymous, hasSentInvitation else { return }
        isShowAccountLink = true
    }

    func tappedResendInvitation() {
        resendingInvitation = waitingInvitation
    }

    func completedShareSheet(_ invitation: CohabitantInvitation, isCompleted: Bool) {
        hasSharedInvitation = isCompleted
        guard isCompleted else { return }
        Task {
            await sentInvitationStore.save(invitation, accountId: loginContext.account.id)
        }
    }

    /// 共有を完了したら、匿名ならApple連携を求める
    /// - Note: 共有シートが閉じきる前に連携のシートを出すと表示されないため、閉じた後に出す
    func dismissedShareSheet() {
        guard hasSharedInvitation else { return }
        hasSharedInvitation = false
        if loginContext.isAnonymous {
            isShowAccountLink = true
        }
    }

    func didAppearNotRegisteredContent() async {
        await sentInvitationStore.loadIfNeeded()
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
