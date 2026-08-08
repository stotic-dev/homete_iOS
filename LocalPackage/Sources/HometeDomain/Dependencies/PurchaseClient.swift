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

    public init(
        logIn: @Sendable @escaping (String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        fetchEntitlementInfo: @Sendable @escaping () async throws -> EntitlementInfo = {
            .init(isActive: false, productIdentifier: "", expirationDate: nil)
        },
        entitlementInfoUpdates: @Sendable @escaping () -> AsyncStream<EntitlementInfo> = { AsyncStream { _ in } },
        showManageSubscriptions: @Sendable @escaping () async throws -> Void = {}
    ) {
        self.logIn = logIn
        self.logOut = logOut
        self.fetchEntitlementInfo = fetchEntitlementInfo
        self.entitlementInfoUpdates = entitlementInfoUpdates
        self.showManageSubscriptions = showManageSubscriptions
    }

}

public extension PurchaseClient {

    static let previewValue = PurchaseClient()

}
