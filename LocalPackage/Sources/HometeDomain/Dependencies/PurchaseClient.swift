//
//  PurchaseClient.swift
//  LocalPackage
//

public struct PurchaseClient: Sendable {

    public let logIn: @Sendable (String) async throws -> Void
    public let logOut: @Sendable () async throws -> Void
    public let fetchEntitlementInfo: @Sendable () async throws -> EntitlementInfo

    public init(
        logIn: @Sendable @escaping (String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        fetchEntitlementInfo: @Sendable @escaping () async throws -> EntitlementInfo = { .init(isActive: false) }
    ) {
        self.logIn = logIn
        self.logOut = logOut
        self.fetchEntitlementInfo = fetchEntitlementInfo
    }

}

public extension PurchaseClient {

    static let previewValue = PurchaseClient()

}
