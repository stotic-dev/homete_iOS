//
//  EntitlementInfo.swift
//  LocalPackage
//

import Foundation

public struct EntitlementInfo: Equatable, Sendable {

    public let isActive: Bool
    /// 購入したプランを識別するプロダクトID（App Store Connect上のプロダクト識別子）
    public let productIdentifier: String
    /// 次回更新日、または有効期限。買い切り(非消費型)プランの場合はnil
    public let expirationDate: Date?

    public init(isActive: Bool, productIdentifier: String, expirationDate: Date?) {
        self.isActive = isActive
        self.productIdentifier = productIdentifier
        self.expirationDate = expirationDate
    }

}
