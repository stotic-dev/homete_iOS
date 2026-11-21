//
//  PurchaseError.swift
//  LocalPackage
//

/// プランの取得・購入ができないときのエラー
public enum PurchaseError: Error, Equatable {

    /// 課金のSDKを初期化していない
    case notConfigured
    /// 表示するプランの一覧が見つからない
    case offeringNotFound
    /// 購入しようとしたプランが、プランの一覧に見つからない
    case packageNotFound

}
