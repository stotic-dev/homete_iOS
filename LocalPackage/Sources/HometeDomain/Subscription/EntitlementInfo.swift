//
//  EntitlementInfo.swift
//  LocalPackage
//

import Foundation

public struct EntitlementInfo: Equatable, Sendable {

    public let isActive: Bool
    /// 購入したプランを識別するプロダクトID（App Store Connect上のプロダクト識別子）
    public let productIdentifier: String
    /// 次回更新日。`willRenew`がfalseの場合は失効日を表す
    public let expirationDate: Date?
    /// 期間終了時に自動更新されるか。ユーザーが解約済みの場合はfalse
    public let willRenew: Bool

    public init(
        isActive: Bool,
        productIdentifier: String,
        expirationDate: Date?,
        willRenew: Bool
    ) {
        self.isActive = isActive
        self.productIdentifier = productIdentifier
        self.expirationDate = expirationDate
        self.willRenew = willRenew
    }

}
