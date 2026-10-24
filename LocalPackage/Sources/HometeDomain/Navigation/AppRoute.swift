//
//  AppRoute.swift
//  LocalPackage
//

public enum AppRoute: Hashable, Sendable {

    /// 同居人登録画面
    case cohabitantRegistration
    /// 招待リンクからの同居人グループ参加画面
    case cohabitantJoin(token: String)
    /// 設定画面
    case setting
    /// 家事テンプレート画面
    case houseworkTemplate
    /// いつもの家事の管理画面
    case frequentHouseworkManagement
    /// プレミアムプランのPaywall画面
    /// - Parameter step: Paywallへの導線。Paywallを実際に出したときに、表示と終了のイベントへ載せる。`nil`なら送らない（デバッグメニュー）
    /// - Note: 匿名のアカウントは購入の前にAppleアカウントとの連携を求め、連携しなければPaywallを出さない
    case paywall(step: PaywallAnalyticsStep?)
    /// 匿名のアカウントをAppleアカウントと連携する画面（シートで出し、閉じられる）
    case accountLink(entry: AccountLinkEntry)
    #if DEBUG
    /// オンボーディング（アカウント登録→Paywall）の確認用デバッグ画面
    case debugOnboarding
    /// P2Pでの同居人登録の確認用デバッグ画面
    case debugCohabitantRegistration
    #endif

}
