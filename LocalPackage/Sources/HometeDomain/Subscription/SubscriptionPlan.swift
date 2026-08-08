//
//  SubscriptionPlan.swift
//  LocalPackage
//

import Foundation
import SwiftUI

/// ユーザーが現在利用しているプランの状態
public enum SubscriptionPlan: Equatable, Sendable {

    /// 無料プラン（未購入）
    case free
    /// サブスクリプション（自動更新あり）
    case subscription(period: SubscriptionPeriod, nextRenewalDate: Date)
    /// 買い切り（非消費型・自動更新なし）
    case lifetime

}

/// サブスクリプションの更新周期
public enum SubscriptionPeriod: Equatable, Sendable {

    case monthly
    case yearly
    /// プロダクトIDから周期を判別できない場合
    case unknown

    public var displayName: LocalizedStringKey {
        switch self {
        case .monthly:
            "月額プラン"

        case .yearly:
            "年額プラン"

        case .unknown:
            "プレミアムプラン"
        }
    }

}

extension SubscriptionPeriod {

    /// プロダクトIDに含まれるキーワードから周期を推定する
    /// - Note: App Store Connect上のプロダクトID命名規則（"monthly"/"yearly"等を含む）に依存する
    init(productIdentifier: String) {
        let lowered = productIdentifier.lowercased()

        if lowered.contains("year") || lowered.contains("annual") {
            self = .yearly
        } else if lowered.contains("month") {
            self = .monthly
        } else {
            self = .unknown
        }
    }

}

public extension EntitlementInfo {

    var plan: SubscriptionPlan {
        guard isActive else { return .free }

        if let expirationDate {
            let period = SubscriptionPeriod(productIdentifier: productIdentifier)
            return .subscription(period: period, nextRenewalDate: expirationDate)
        } else {
            return .lifetime
        }
    }

}
