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

    public init(
        purchaseClient: PurchaseClient = .previewValue,
        entitlementInfo: EntitlementInfo? = nil
    ) {
        self.purchaseClient = purchaseClient
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
    }

    public func refresh() async {
        do {
            entitlementInfo = try await purchaseClient.fetchEntitlementInfo()
        } catch {
            print("failed to fetch entitlement info: \(error)")
        }
    }

    /// エンタイトルメント状態の更新を監視し続け、都度反映する
    /// - Note: 呼び出し元でTaskとして起動し、Store生存期間中バックグラウンドで購読させる想定
    public func observeEntitlementUpdates() async {
        for await info in purchaseClient.entitlementInfoUpdates() {
            entitlementInfo = info
        }
    }

    /// 購入済みユーザー向けにOSのサブスクリプション管理画面を表示する
    public func showManageSubscriptions() async {
        do {
            try await purchaseClient.showManageSubscriptions()
        } catch {
            print("failed to show manage subscriptions: \(error)")
        }
    }

}
