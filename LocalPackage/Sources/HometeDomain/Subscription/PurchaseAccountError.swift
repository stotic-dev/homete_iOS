//
//  PurchaseAccountError.swift
//  LocalPackage
//

/// 購入者（RevenueCatのApp User ID）をアカウントに結び付けられないときのエラー
public enum PurchaseAccountError: Error, Equatable {

    /// ログインし直しても、購入者が匿名のIDのまま
    case notLoggedIn

}
