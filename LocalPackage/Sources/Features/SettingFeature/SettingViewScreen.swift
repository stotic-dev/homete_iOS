//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeDomain
import SettingFeatureUI
import HometeUI
import SwiftUI

public struct SettingViewScreen: View {

    @Environment(\.routeResolver) var router
    @Environment(\.scenePhase) var scenePhase
    @Environment(PendingRouteStore.self) var pendingRouteStore

    @State var navigationPath = AppNavigationPath<SettingRoute>()
    @State var isShowHouseworkTemplate = false
    @State var isShowFrequentHousework = false
    /// 導線のバッジと問い合わせの一覧で同じ状態を使う
    @State var inquiryListStore: InquiryListStore

    public static func make() -> some View {
        DependenciesInjectLayer {
            SettingViewScreen(inquiryListStore: .init(inquiryClient: $0.inquiryClient))
        }
    }

    init(inquiryListStore: InquiryListStore) {
        _inquiryListStore = State(initialValue: inquiryListStore)
    }

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            SettingMenuScreen(
                isShowHouseworkTemplate: $isShowHouseworkTemplate,
                isShowFrequentHousework: $isShowFrequentHousework
            )
            .navigationDestination(for: SettingRoute.self) { route in
                navigationHandler(route)
            }
        }
        // pushした画面にも届くよう、NavigationStackの外から渡す。
        // ルートのViewに付けると遷移先には届かず、遷移先からのpushが既定値の別のパスに積まれて何も起きない
        .environment(\.settingNavigationPath, navigationPath)
        .environment(inquiryListStore)
        .task {
            // 導線に未読のバッジを出すため、設定画面を開いたら取得する
            await inquiryListStore.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await inquiryListStore.refresh()
            }
        }
        .onChange(of: pendingRouteStore.pendingRoute, initial: true) {
            openPendingInquiryDetail()
        }
        // NavigationStackの中で出すと、出した画面がシートを出した直後に作り直されて
        // `@State`ごと初期化され、追加・編集のシートがすぐ閉じてしまう。NavigationStackの外から出す
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowFrequentHousework) {
            router.resolve(.frequentHouseworkManagement)
        }
    }

}

private extension SettingViewScreen {

    @ViewBuilder
    func navigationHandler(_ route: SettingRoute) -> some View {
        switch route {
        case .licenseList:
            LicenseListView { license in
                navigationPath.push(.licenseDetail(license))
            }
            .trackScreenView(.licenseList)

        case let .licenseDetail(license):
            LicenseDetailView(license: license)
                .trackScreenView(.licenseDetail)

        case .subscriptionManagement:
            SubscriptionManagementScreen()

        case .notificationPermission:
            SettingNotificationScreen()

        case .inquiryList:
            InquiryListScreen()

        case let .inquiryDetail(inquiryId):
            InquiryDetailScreen(inquiryId: inquiryId)

        #if DEBUG
        case .debugMenu:
            DebugMenuView()
        #endif
        }
    }

    /// 通知から開く問い合わせがあれば、その詳細画面を開く
    /// - Note: 別の画面を開いていても、問い合わせの一覧と詳細だけが積まれた状態にする。詳細から戻ると一覧が見える。
    ///         家事テンプレートなどのフルスクリーンカバーは閉じず、その裏に詳細画面を積む。
    ///         削除された・別のアカウントの問い合わせだった場合は、詳細画面が見つからないと表示する
    func openPendingInquiryDetail() {
        guard let inquiryId = pendingRouteStore.takeInquiryDetailId() else { return }
        navigationPath.path = [.inquiryList, .inquiryDetail(inquiryId: inquiryId)]
    }

}

struct SettingMenuScreen: View {

    @Environment(AccountStore.self) var accountStore
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(SentInvitationStore.self) var sentInvitationStore
    @Environment(InquiryListStore.self) var inquiryListStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var cohabitantMembers
    @Environment(\.routeResolver) var router
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.settingNavigationPath) var navigationPath
    @Environment(\.appDependencies.cohabitantInvitationClient) var cohabitantInvitationClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @LoadingState var loadingState
    @CommonError var errorContent

    @State var isPresentedLogoutConfirmAlert = false
    @State var isPresentedAccountDeletionConfirmAlert = false
    @Binding var isShowHouseworkTemplate: Bool
    @Binding var isShowFrequentHousework: Bool
    @State var sharingInvitation: CohabitantInvitation?
    @State var isShowPaywall = false
    @State var isShowAccountLink = false

    init(isShowHouseworkTemplate: Binding<Bool>, isShowFrequentHousework: Binding<Bool>) {
        _isShowHouseworkTemplate = isShowHouseworkTemplate
        _isShowFrequentHousework = isShowFrequentHousework
    }

    var body: some View {
        SettingView(
            userName: loginContext.account.userName,
            plan: subscriptionStore.plan,
            otherMembers: cohabitantMembers.others,
            menuGroups: menuGroups,
            unreadInquiryCount: inquiryListStore.state.unreadCount,
            isAnonymous: loginContext.isAnonymous,
            onTapMenuItem: tappedSettingMenuItem,
            onTapAccountLink: { tappedAccountLinkButton() },
            onTapLogout: { tappedLogoutRowButton() },
            onTapAccountDeletion: { tappedAccountDeletionRowButton() },
            onTapClose: { dismiss() }
        )
        .shareSheet(
            item: $sharingInvitation,
            text: CohabitantInvitation.shareMessage,
            url: \.url,
            onFinish: { invitation, isCompleted in
                finishedShareSheet(invitation, isCompleted: isCompleted)
            }
        )
        .sheet(isPresented: $isShowAccountLink) {
            router.resolve(.accountLink(entry: .setting))
        }
        .commonError(content: $errorContent)
        .fullScreenLoadingIndicator(loadingState)
        .alert(.localized("ログアウトしますか？"), isPresented: $isPresentedLogoutConfirmAlert) {
            Button(.localized("ログアウト"), role: .destructive) {
                tappedLogoutAlertOkButton()
            }
        }
        .alert(.localized("退会しますか？"), isPresented: $isPresentedAccountDeletionConfirmAlert) {
            accountDeletionAlertActions(plan: subscriptionStore.plan)
        } message: {
            Text(accountDeletionAlertMessage(plan: subscriptionStore.plan))
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            content: { router.resolve(.paywall(step: .setting)) }
        )
        .trackScreenView(.setting)
    }

}

// MARK: - 表示内容

private extension SettingMenuScreen {

    var menuGroups: [SettingMenuGroup] {
        SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: loginContext.hasCohabitant,
            isAvailableInvitationLink: CohabitantInvitationLink.isAvailable
        ))
    }

    /// 自動更新中の場合は、退会だけでは課金が止まらないため解約導線を併せて提示する
    @ViewBuilder
    func accountDeletionAlertActions(plan: SubscriptionPlan) -> some View {
        if plan.willAutoRenew {
            Button(.localized("解約手続きへ")) {
                tappedManageSubscriptionInDeletionAlert()
            }
        }
        Button(.localized("退会する"), role: .destructive) {
            loadingState.task {
                await tappedAccountDeletionAlertOkButton()
            }
        }
    }

    func accountDeletionAlertMessage(plan: SubscriptionPlan) -> LocalizedStringResource {
        guard plan.willAutoRenew else {
            return .localized("""
            あなたのデータは全て削除され、復元することはできません。
            また、現在参加しているグループが2名以下の場合は、グループごと削除されます。
            """)
        }

        return .localized("""
        退会してもサブスクリプションは解約されず、料金の請求が続きます。先に解約手続きを行ってください。
        また、あなたのデータは全て削除され、復元することはできません。現在参加しているグループが2名以下の場合は、グループごと削除されます。
        """)
    }

}

// MARK: プレゼンテーションロジック

private extension SettingMenuScreen {

    func tappedSettingMenuItem(_ item: SettingMenuItem) {
        switch item {
        case .taskTemplate:
            isShowHouseworkTemplate = true

        case .frequentHousework:
            isShowFrequentHousework = true

        case .notificationPermission:
            navigationPath.push(.notificationPermission)

        case .memberInvitation:
            loadingState.task {
                await tappedMemberInvitationItem()
            }

        case .premiumPlan:
            tappedPremiumPlanItem()

        case .inquiry:
            navigationPath.push(.inquiryList)

        case .termsOfService:
            openExternalPage(Constants.termsOfServiceURLString)

        case .privacyPolicy:
            openExternalPage(Constants.privacyPolicyURLString)

        case .license:
            navigationPath.push(.licenseList)

        #if DEBUG
        case .debugMenu:
            navigationPath.push(.debugMenu)
        #endif
        }
    }

    /// 規約などのページを外部のブラウザで開く
    func openExternalPage(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }

    /// 招待リンクを発行して共有シートを開く
    func tappedMemberInvitationItem() async {
        do {
            let invitation = try await cohabitantInvitationClient.issue()
            sharingInvitation = invitation
            analyticsClient.log(.cohabitantInvitation(.issued(screen: .setting, isSuccess: true)))
        } catch {
            errorContent = .init(error: error)
            analyticsClient.log(.cohabitantInvitation(.issued(screen: .setting, isSuccess: false)))
        }
    }

    func tappedPremiumPlanItem() {
        switch subscriptionStore.plan {
        case .free:
            isShowPaywall = true

        case .subscription:
            navigationPath.push(.subscriptionManagement)
        }
    }

    /// 匿名のまま招待を送ると、相手が参加した時点でApple連携の画面から先に進めなくなる。
    /// 共有を終えたその場で連携してもらう
    func finishedShareSheet(_ invitation: CohabitantInvitation, isCompleted: Bool) {
        guard isCompleted else { return }
        Task {
            await sentInvitationStore.save(invitation, accountId: loginContext.account.id)
        }
        if loginContext.isAnonymous {
            isShowAccountLink = true
        }
    }

    func tappedAccountLinkButton() {
        isShowAccountLink = true
    }

    func tappedLogoutRowButton() {
        isPresentedLogoutConfirmAlert = true
    }

    func tappedLogoutAlertOkButton() {
        accountAuthStore.logOut()
    }

    func tappedAccountDeletionRowButton() {
        isPresentedAccountDeletionConfirmAlert = true
    }

    func tappedManageSubscriptionInDeletionAlert() {
        navigationPath.push(.subscriptionManagement)
    }

    func tappedAccountDeletionAlertOkButton() async {
        do {
            try await accountAuthStore.deleteAccount()
        } catch {
            // TODO: エラーハンドリング
            print("occurred error: \(error)")
        }
    }

}
