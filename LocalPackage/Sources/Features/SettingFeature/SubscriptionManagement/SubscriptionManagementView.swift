//
//  SubscriptionManagementView.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

/// 契約中プランの確認・変更・復元・解約導線をまとめた画面
/// - Note: 解約はStoreKitのAPIで実行できないため、解約ボタンのみOSの管理画面へ委譲する
struct SubscriptionManagementView: View {

    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.routeResolver) var router
    @LoadingState var loadingState

    @State var isShowPaywall = false
    @State var isPresentedRestoreResultAlert = false
    @State var restoreResultMessage: LocalizedStringKey = ""

    var body: some View {
        ScrollView {
            VStack(spacing: .space32) {
                currentPlanSection(plan: subscriptionStore.plan)
                actionSection(plan: subscriptionStore.plan)
            }
            .frame(maxWidth: .infinity)
            .padding(.space16)
        }
        .navigationTitle("サブスクリプション管理")
        .inlineNavigationBarTitleDisplayMode()
        .fullScreenLoadingIndicator(loadingState)
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
        .alert("購入の復元", isPresented: $isPresentedRestoreResultAlert) {
            Button("OK") {}
        } message: {
            Text(restoreResultMessage)
        }
    }

}

// MARK: - UI定義

private extension SubscriptionManagementView {

    func currentPlanSection(plan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            sectionHeader
            planCard(plan: plan)
        }
    }

    var sectionHeader: some View {
        HStack(spacing: .space8) {
            Image(systemName: "crown.fill")
                .foregroundStyle(.onSurface)
            Text("現在のプラン")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
        }
    }

    @ViewBuilder
    func planCard(plan: SubscriptionPlan) -> some View {
        switch plan {
        case .free:
            Text("プレミアムプランには登録していません")
                .font(with: .body)
                .foregroundStyle(.onSubSurface)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
                .background(.subSurface)
                .cornerRadius(.radius16)

        case let .subscription(period, nextRenewalDate, willRenew):
            VStack(spacing: .space8) {
                planRow(title: "プラン", value: Text(period.displayName))
                if let nextRenewalDate {
                    Divider()
                    planRow(
                        title: willRenew ? "次回更新日" : "有効期限",
                        value: Text(nextRenewalDate.formatted(date: .abbreviated, time: .omitted))
                    )
                }
                Divider()
                planRow(title: "自動更新", value: Text(willRenew ? "オン" : "オフ"))
            }
            .padding(.space16)
            .background(.subSurface)
            .cornerRadius(.radius16)
        }
    }

    func planRow(title: LocalizedStringKey, value: Text) -> some View {
        HStack(spacing: .zero) {
            Text(title)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
            value
                .font(with: .body)
                .foregroundStyle(.onSurface)
                .lineLimit(1)
        }
    }

    func actionSection(plan: SubscriptionPlan) -> some View {
        VStack(spacing: .space16) {
            Button {
                tappedChangePlanButton()
            } label: {
                Text(plan == .free ? "プレミアムプランに登録" : "プランを変更")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            Button {
                tappedRestorePurchasesButton()
            } label: {
                Text("購入を復元")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
            manageSubscriptionContent(plan: plan)
        }
    }

    @ViewBuilder
    func manageSubscriptionContent(plan: SubscriptionPlan) -> some View {
        if case let .subscription(_, _, willRenew) = plan {
            VStack(spacing: .space8) {
                Button {
                    tappedManageSubscriptionButton()
                } label: {
                    Text(willRenew ? "解約する" : "サブスクリプションを管理")
                        .frame(maxWidth: .infinity)
                }
                .modifier(ManageSubscriptionButtonStyle(isCancelable: willRenew))
                Text("解約手続きはApp Storeの管理画面で行います")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
            }
        }
    }

}

/// 解約可能な状態のみ警告色のボタンにする
private struct ManageSubscriptionButtonStyle: ViewModifier {

    let isCancelable: Bool

    func body(content: Content) -> some View {
        if isCancelable {
            content.destructiveButtonStyle()
        } else {
            content.subPrimaryButtonStyle()
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension SubscriptionManagementView {

    func tappedChangePlanButton() {
        isShowPaywall = true
    }

    func tappedRestorePurchasesButton() {
        loadingState.task {
            await restorePurchases()
        }
    }

    func restorePurchases() async {
        do {
            let isRestored = try await subscriptionStore.restorePurchases()
            restoreResultMessage = isRestored
                ? "購入を復元しました"
                : "復元できる購入が見つかりませんでした"
        } catch {
            restoreResultMessage = "購入の復元に失敗しました。時間をおいて再度お試しください"
        }
        isPresentedRestoreResultAlert = true
    }

    func tappedManageSubscriptionButton() {
        loadingState.task {
            await subscriptionStore.showManageSubscriptions()
        }
    }

}

// MARK: - Preview定義

#Preview("SubscriptionManagementView_月額") {
    NavigationStack {
        SubscriptionManagementView()
            .environment(SubscriptionStore(entitlementInfo: .init(
                isActive: true,
                productIdentifier: "premium_monthly",
                expirationDate: .now.addingTimeInterval(60 * 60 * 24 * 30),
                willRenew: true
            )))
    }
}

#Preview("SubscriptionManagementView_年額") {
    NavigationStack {
        SubscriptionManagementView()
            .environment(SubscriptionStore(entitlementInfo: .init(
                isActive: true,
                productIdentifier: "premium_yearly",
                expirationDate: .now.addingTimeInterval(60 * 60 * 24 * 365),
                willRenew: true
            )))
    }
}

#Preview("SubscriptionManagementView_解約済み") {
    NavigationStack {
        SubscriptionManagementView()
            .environment(SubscriptionStore(entitlementInfo: .init(
                isActive: true,
                productIdentifier: "premium_monthly",
                expirationDate: .now.addingTimeInterval(60 * 60 * 24 * 10),
                willRenew: false
            )))
    }
}

#Preview("SubscriptionManagementView_未登録") {
    NavigationStack {
        SubscriptionManagementView()
            .environment(SubscriptionStore())
    }
}
