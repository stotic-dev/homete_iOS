//
//  AppRoute.swift
//  LocalPackage
//

public enum AppRoute: Hashable {
    /// 家事詳細画面
    case houseworkDetail(HouseworkItem)
    /// 家事承認画面
    case houseworkApproval(HouseworkItem)
    /// 同居人登録画面
    case cohabitantRegistration
    /// 設定画面
    case setting
}
