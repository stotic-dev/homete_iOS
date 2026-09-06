//
//  SubscriptionStore.swift
//  LocalPackage
//

import Observation

@MainActor
@Observable
public final class SubscriptionStore {

    public private(set) var entitlementInfo: EntitlementInfo?

    private let purchaseClient: PurchaseClient
    private let analyticsClient: AnalyticsClient

    public init(
        purchaseClient: PurchaseClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        entitlementInfo: EntitlementInfo? = nil
    ) {
        self.purchaseClient = purchaseClient
        self.analyticsClient = analyticsClient
        self.entitlementInfo = entitlementInfo
    }

    public var isPremium: Bool {
        entitlementInfo?.isActive ?? false
    }

    public var plan: SubscriptionPlan {
        entitlementInfo?.plan ?? .free
    }

    public func logIn(_ accountId: String) async {
        do {
            try await purchaseClient.logIn(accountId)
            await refresh()
        } catch {
            print("failed to logIn to purchase client: \(error)")
        }
    }

    public func logOut() async {
        do {
            try await purchaseClient.logOut()
        } catch {
            print("failed to logOut from purchase client: \(error)")
        }
        entitlementInfo = nil
        analyticsClient.setUserProperty(.isPremium(isPremium))
    }

    public func refresh() async {
        do {
            entitlementInfo = try await purchaseClient.fetchEntitlementInfo()
            analyticsClient.setUserProperty(.isPremium(isPremium))
        } catch {
            print("failed to fetch entitlement info: \(error)")
        }
    }

    /// エンタイトルメント状態の更新を監視し続け、都度反映する
    /// - Note: 呼び出し元でTaskとして起動し、Store生存期間中バックグラウンドで購読させる想定
    public func observeEntitlementUpdates() async {
        for await info in purchaseClient.entitlementInfoUpdates() {
            entitlementInfo = info
            analyticsClient.setUserProperty(.isPremium(isPremium))
        }
    }

    /// 解約はStoreKitのAPIで実行できないため、OSのサブスクリプション管理画面へ委譲する
    public func showManageSubscriptions() async {
        do {
            try await purchaseClient.showManageSubscriptions()
        } catch {
            print("failed to show manage subscriptions: \(error)")
            analyticsClient.log(.subscription(.manageOpened(isSuccess: false)))
            return
        }
        analyticsClient.log(.subscription(.manageOpened(isSuccess: true)))
    }

    /// 過去の購入を復元する
    /// - Returns: 復元の結果、有効なエンタイトルメントが得られたか
    /// - Note: 結果をユーザーに提示する必要があるため、他のメソッドと異なりエラーを握り潰さない
    @discardableResult
    public func restorePurchases() async throws -> Bool {
        do {
            let restoredInfo = try await purchaseClient.restorePurchases()
            entitlementInfo = restoredInfo
            analyticsClient.setUserProperty(.isPremium(isPremium))
            analyticsClient.log(.subscription(.restore(isSuccess: true)))
            return restoredInfo.isActive
        } catch {
            analyticsClient.log(.subscription(.restore(isSuccess: false)))
            throw error
        }
    }

}
