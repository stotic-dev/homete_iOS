//
//  PaywallBenefit.swift
//  LocalPackage
//

/// Paywallで訴求するプレミアムプランの特典。並び順のとおりに表示する
///
/// 特典を足すときは、ケースと`PaywallBenefitListContent`の見せ方を1つずつ足す。
/// 訴求する前に、その特典がプラン判定（`HouseworkImagePolicy`など）で実際に解放されていることを確かめる（`ux-writing.md`の原則4）
enum PaywallBenefit: CaseIterable {

    /// 広告が表示されない（`AdDisplayPolicy`）
    case noAds
    /// 家事の記録を期間の制限なく振り返れる（`HouseworkStoragePolicy`）
    case unlimitedHistory
    /// 家事に写真を添えられる（`HouseworkImagePolicy`）
    case houseworkImage

}
