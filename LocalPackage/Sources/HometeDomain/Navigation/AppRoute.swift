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
    /// プレミアムプランのPaywall画面
    case paywall
    #if DEBUG
    /// オンボーディング（アカウント登録→Paywall）の確認用デバッグ画面
    case debugOnboarding
    #endif

}
