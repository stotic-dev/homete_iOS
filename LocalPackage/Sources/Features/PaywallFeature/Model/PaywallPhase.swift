//
//  PaywallPhase.swift
//  LocalPackage
//

import HometeDomain

/// Paywallに何を出しているか
enum PaywallPhase: Equatable {

    /// プランの一覧を取得している
    case loading
    /// プランの一覧を出している
    case loaded(PurchaseOffering)
    /// プランの一覧を取得できなかった
    case loadFailed
    /// 購入（または復元）が完了し、お礼を出している
    case completed

}

/// Paywallで出すアラート
enum PaywallAlert: Equatable {

    /// 購入に失敗した
    case purchaseFailed
    /// 購入が承認待ちになった
    case purchasePending
    /// 復元できる購入が見つからなかった
    case restoreNotFound
    /// 復元に失敗した
    case restoreFailed

}
