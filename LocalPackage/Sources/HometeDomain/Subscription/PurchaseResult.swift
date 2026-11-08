//
//  PurchaseResult.swift
//  LocalPackage
//

/// プランを購入した結果
public enum PurchaseResult: Equatable, Sendable {

    /// 購入が完了した。購入後のエンタイトルメント状態を持つ
    case purchased(EntitlementInfo)
    /// ユーザーが購入をキャンセルした
    case cancelled
    /// 承認待ち（ペアレンタルコントロールの「承認と購入のリクエスト」など）。承認されるとエンタイトルメントの更新で届く
    case pending

}
