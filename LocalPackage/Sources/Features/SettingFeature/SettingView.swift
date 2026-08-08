//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct SettingViewScreen: View {

    @State var navigationPath = AppNavigationPath<SettingRoute>()

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            SettingView()
                .navigationDestination(for: SettingRoute.self) { route in
                    navigationHandler(route)
                }
                .environment(\.settingNavigationPath, navigationPath)
        }
    }

}

private extension SettingViewScreen {

    @ViewBuilder
    func navigationHandler(_ route: SettingRoute) -> some View {
        switch route {
        case .licenseList:
            LicenseListView()

        case let .licenseDetail(license):
            LicenseDetailView(license: license)
        }
    }

}

struct SettingView: View {

    @Environment(AccountStore.self) var accountStore
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var cohabitantMembers
    @Environment(\.routeResolver) var router
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.settingNavigationPath) var navigationPath
    @LoadingState var loadingState

    @State var isPresentedLogoutConfirmAlert = false
    @State var isPresentedAccountDeletionConfirmAlert = false
    @State var isShowHouseworkTemplate = false
    @State var isShowMemberRegistration = false
    @State var isShowPaywall = false

    init() {}

    var body: some View {
        // 表示項目が画面高さを超えるとナビゲーションバー領域にコンテンツが食い込むためScrollViewで包む
        ScrollView {
            VStack(spacing: .space32) {
                VStack(spacing: .space24) {
                    basicInfoSection(plan: subscriptionStore.plan)
                    GroupMemberListView(members: cohabitantMembers.others)
                    Spacer()
                        .frame(height: .space16)
                    VStack(spacing: .zero) {
                        ForEach(
                            SettingMenuItem.displayItems(loginContext.hasCohabitant),
                            id: \.self
                        ) { item in
                            SettingMenuItemButton(item: item, plan: subscriptionStore.plan) {
                                tappedSettingMenuItem(item)
                            }
                        }
                    }
                }
                VStack(spacing: .space24) {
                    Button {
                        tappedLogoutRowButton()
                    } label: {
                        Text("ログアウト")
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                    Button {
                        tappedAccountDeletionRowButton()
                    } label: {
                        Text("退会")
                            .frame(maxWidth: .infinity)
                    }
                    .destructiveButtonStyle()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space16)
        }
        .navigationTitle("設定")
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            leadingNavigationBarContent()
        }
        .fullScreenCoverOnIOS(isPresented: $isShowMemberRegistration) {
            router.resolve(.cohabitantRegistration)
        }
        .fullScreenLoadingIndicator(loadingState)
        .alert("ログアウトしますか？", isPresented: $isPresentedLogoutConfirmAlert) {
            Button("ログアウト", role: .destructive) {
                tappedLogoutAlertOkButton()
            }
        }
        .alert("退会しますか？", isPresented: $isPresentedAccountDeletionConfirmAlert) {
            Button("退会する", role: .destructive) {
                loadingState.task {
                    await tappedAccountDeletionAlertOkButton()
                }
            }
        } message: {
            Text("あなたのデータは全て削除され、復元することはできません。\nまた、現在参加しているグループが2名以下の場合は、グループごと削除されます。")
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
    }

}

private extension SettingView {

    func leadingNavigationBarContent() -> some View {
        NavigationBarButton(label: .close) {
            dismiss()
        }
    }

    func basicInfoSection(plan: SubscriptionPlan) -> some View {
        VStack(spacing: .space8) {
            HStack(spacing: .zero) {
                Text("ユーザー名:")
                    .font(with: .headLineS)
                Spacer()
                Text(loginContext.account.userName)
                    .font(with: .body)
                    .lineLimit(1)
            }
            HStack(spacing: .zero) {
                Text("ご利用中のプラン:")
                    .font(with: .headLineS)
                Spacer()
                VStack(alignment: .trailing, spacing: .space4) {
                    switch plan {
                    case .free:
                        Text("無料プラン")
                            .font(with: .body)

                    case let .subscription(period, nextRenewalDate):
                        Text(period.displayName)
                            .font(with: .body)
                            .lineLimit(1)
                        Text("次回更新日: \(nextRenewalDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(with: .caption)

                    case .lifetime:
                        Text("買い切りプラン")
                            .font(with: .body)
                            .lineLimit(1)
                        Text("有効期限: なし")
                            .font(with: .caption)
                    }
                }
            }
        }
    }

}

// MARK: プレゼンテーションロジック

private extension SettingView {

    func tappedSettingMenuItem(_ item: SettingMenuItem) {
        switch item {
        case .taskTemplate:
            isShowHouseworkTemplate = true

        case .memberRegistration:
            isShowMemberRegistration = true

        case .premiumPlan:
            tappedPremiumPlanItem()

        case .termsOfService:
            if let url = URL(string: Constants.termsOfServiceURLString) {
                openURL(url)
            }

        case .privacyPolicy:
            if let url = URL(string: Constants.privacyPolicyURLString) {
                openURL(url)
            }

        case .license:
            navigationPath.push(.licenseList)
        }
    }

    func tappedPremiumPlanItem() {
        switch subscriptionStore.plan {
        case .free:
            isShowPaywall = true

        case .subscription:
            loadingState.task {
                await subscriptionStore.showManageSubscriptions()
            }

        case .lifetime:
            // 買い切りプランはサブスクリプションへの切り替えを技術的にサポートできないため、
            // ボタン自体が無効化されておりここには到達しない
            break
        }
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

    func tappedAccountDeletionAlertOkButton() async {
        do {
            try await accountAuthStore.deleteAccount()
        } catch {
            // TODO: エラーハンドリング
            print("occurred error: \(error)")
        }
    }

}

#Preview("SettingView_グループ未登録") {
    SettingView()
        .environment(AccountAuthStore())
        .environment(AccountStore())
        .environment(SubscriptionStore())
        .environment(\.loginContext, .init(account: .init(
            id: "",
            userName: "Hoge",
            fcmToken: "",
            cohabitantId: ""
        )))
}

#Preview("SettingView_グループ登録済み") {
    SettingView()
        .environment(AccountAuthStore())
        .environment(AccountStore())
        .environment(SubscriptionStore())
        .environment(\.loginContext, .init(account: .init(
            id: "",
            userName: "Hoge",
            fcmToken: "",
            cohabitantId: ""
        )))
        .environment(
            \.cohabitantMembers,
            .init(
                value: [
                    .init(id: "ownId", userName: "自分"),
                    .init(id: "user1", userName: "山田太郎"),
                    .init(id: "user2", userName: "佐藤花子"),
                ],
                ownId: "ownId"
            )
        )
}

#Preview("SettingView_プレミアム登録済み") {
    SettingView()
        .environment(AccountAuthStore())
        .environment(AccountStore())
        .environment(SubscriptionStore(entitlementInfo: .init(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: .now.addingTimeInterval(60 * 60 * 24 * 30)
        )))
        .environment(\.loginContext, .init(account: .init(
            id: "",
            userName: "Hoge",
            fcmToken: "",
            cohabitantId: ""
        )))
        .environment(
            \.cohabitantMembers,
            .init(
                value: [
                    .init(id: "ownId", userName: "自分"),
                    .init(id: "user1", userName: "山田太郎"),
                    .init(id: "user2", userName: "佐藤花子"),
                ],
                ownId: "ownId"
            )
        )
}

#Preview("SettingView_プレミアム登録済み_買い切り") {
    SettingView()
        .environment(AccountAuthStore())
        .environment(AccountStore())
        .environment(SubscriptionStore(entitlementInfo: .init(
            isActive: true,
            productIdentifier: "premium_lifetime",
            expirationDate: nil
        )))
        .environment(\.loginContext, .init(account: .init(
            id: "",
            userName: "Hoge",
            fcmToken: "",
            cohabitantId: ""
        )))
        .environment(
            \.cohabitantMembers,
            .init(
                value: [
                    .init(id: "ownId", userName: "自分"),
                    .init(id: "user1", userName: "山田太郎"),
                    .init(id: "user2", userName: "佐藤花子"),
                ],
                ownId: "ownId"
            )
        )
}
