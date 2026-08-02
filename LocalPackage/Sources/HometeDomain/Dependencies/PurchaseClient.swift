//
//  PurchaseClient.swift
//  LocalPackage
//

public struct PurchaseClient: Sendable {

    public let logIn: @Sendable (String) async throws -> Void
    public let logOut: @Sendable () async throws -> Void
    public let fetchEntitlementInfo: @Sendable () async throws -> EntitlementInfo
    public let entitlementInfoUpdates: @Sendable () -> AsyncStream<EntitlementInfo>

    public init(
        logIn: @Sendable @escaping (String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        fetchEntitlementInfo: @Sendable @escaping () async throws -> EntitlementInfo = { .init(isActive: false) },
        entitlementInfoUpdates: @Sendable @escaping () -> AsyncStream<EntitlementInfo> = { AsyncStream { _ in } }
    ) {
        self.logIn = logIn
        self.logOut = logOut
        self.fetchEntitlementInfo = fetchEntitlementInfo
        self.entitlementInfoUpdates = entitlementInfoUpdates
    }

}

public extension PurchaseClient {

    static let previewValue = PurchaseClient()

}
