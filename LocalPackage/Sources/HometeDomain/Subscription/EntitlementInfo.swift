//
//  EntitlementInfo.swift
//  LocalPackage
//

public struct EntitlementInfo: Equatable, Sendable {

    public let isActive: Bool

    public init(isActive: Bool) {
        self.isActive = isActive
    }

}
