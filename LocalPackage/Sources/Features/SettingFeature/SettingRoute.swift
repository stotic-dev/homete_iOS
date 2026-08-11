//
//  SettingRoute.swift
//  homete
//

import HometeUI
import SwiftUI

enum SettingRoute: Hashable {

    /// ライセンス一覧画面
    case licenseList
    /// ライセンス詳細画面
    case licenseDetail(OSSLicense)
    /// サブスクリプション管理画面
    case subscriptionManagement
    #if DEBUG
    /// デバッグメニュー画面
    case debugMenu
    #endif

}

extension EnvironmentValues {

    @Entry var settingNavigationPath = AppNavigationPath<SettingRoute>()

}
