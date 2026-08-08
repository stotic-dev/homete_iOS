//
//  PurchaseClient.swift
//  LocalPackage
//

public struct PurchaseClient: Sendable {

    public let logIn: @Sendable (String) async throws -> Void
    public let logOut: @Sendable () async throws -> Void
    public let fetchEntitlementInfo: @Sendable () async throws -> EntitlementInfo
    public let entitlementInfoUpdates: @Sendable () -> AsyncStream<EntitlementInfo>
    public let showManageSubscriptions: @Sendable () async throws -> Void
    /// 過去の購入を復元し、復元後のエンタイトルメント状態を返す
    public let restorePurchases: @Sendable () async throws -> EntitlementInfo

    public init(
        logIn: @Sendable @escaping (String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        fetchEntitlementInfo: @Sendable @escaping () async throws -> EntitlementInfo = {
            .init(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
        },
        entitlementInfoUpdates: @Sendable @escaping () -> AsyncStream<EntitlementInfo> = { AsyncStream { _ in } },
        showManageSubscriptions: @Sendable @escaping () async throws -> Void = {},
        restorePurchases: @Sendable @escaping () async throws -> EntitlementInfo = {
            .init(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
        }
    ) {
        self.logIn = logIn
        self.logOut = logOut
        self.fetchEntitlementInfo = fetchEntitlementInfo
        self.entitlementInfoUpdates = entitlementInfoUpdates
        self.showManageSubscriptions = showManageSubscriptions
        self.restorePurchases = restorePurchases
    }

}

public extension PurchaseClient {

    static let previewValue = PurchaseClient()

}
