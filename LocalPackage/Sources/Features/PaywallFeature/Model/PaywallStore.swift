//
//  PaywallStore.swift
//  LocalPackage
//

import HometeDomain
import Observation

/// Paywallの状態と、プランの取得・購入・復元を受け持つStore
@MainActor
@Observable
final class PaywallStore {

    private(set) var phase: PaywallPhase = .loading
    /// 選んでいるプランの`PurchasePackage.id`。選べるプランが無ければnil
    var selectedPackageId: String?
    /// 出しているアラート。閉じたらnilに戻す
    var alert: PaywallAlert?

    private let accountId: String
    private let purchaseClient: PurchaseClient
    private let errorReportClient: ErrorReportClient
    private let subscriptionStore: SubscriptionStore

    /// - Parameter accountId: 購入・復元を結び付けるアカウントのID
    init(
        accountId: String,
        purchaseClient: PurchaseClient,
        errorReportClient: ErrorReportClient,
        subscriptionStore: SubscriptionStore
    ) {
        self.accountId = accountId
        self.purchaseClient = purchaseClient
        self.errorReportClient = errorReportClient
        self.subscriptionStore = subscriptionStore
    }

    /// 契約中のプランのプロダクトID。契約していなければnil
    var subscribedProductIdentifier: String? {
        guard let info = subscriptionStore.entitlementInfo, info.isActive else { return nil }
        return info.productIdentifier
    }

    /// プランの一覧を取得し、最初に選ぶプランを決める
    func load() async {
        phase = .loading
        do {
            let offering = try await purchaseClient.fetchOffering()
            guard !offering.packages.isEmpty else { throw PurchaseError.offeringNotFound }
            selectedPackageId = initialSelectedPackageId(in: offering)
            phase = .loaded(offering)
        } catch {
            // 「商品が取れない」問題を追えるよう、取得の失敗も記録する
            errorReportClient.record(error, ["operation": "fetch_offering"])
            phase = .loadFailed
        }
    }

    /// 選んでいるプランを購入する
    func purchase() async {
        guard let packageId = selectedPackageId else { return }
        do {
            switch try await subscriptionStore.purchase(packageId, for: accountId) {
            case .purchased:
                phase = .completed

            case .cancelled:
                break

            case .pending:
                alert = .purchasePending
            }
        } catch {
            errorReportClient.record(error, ["operation": "purchase", "package_id": packageId])
            alert = .purchaseFailed
        }
    }

    /// 過去の購入を復元する。復元できたら購入と同じくお礼を出す
    func restore() async {
        do {
            let isRestored = try await subscriptionStore.restorePurchases(for: accountId)
            if isRestored {
                phase = .completed
            } else {
                alert = .restoreNotFound
            }
        } catch {
            alert = .restoreFailed
        }
    }

}

private extension PaywallStore {

    /// 年額を選ぶ。年額が無い・契約中なら、契約中でない先頭のプランを選ぶ
    func initialSelectedPackageId(in offering: PurchaseOffering) -> String? {
        let selectable = offering.packages.filter { $0.productIdentifier != subscribedProductIdentifier }
        return (selectable.first { $0.period == .yearly } ?? selectable.first)?.id
    }

}
