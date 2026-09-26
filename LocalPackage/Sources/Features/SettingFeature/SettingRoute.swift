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
    /// 通知設定画面（権限が無い場合は権限の案内、ある場合はふりかえり通知の設定）
    case notificationPermission
    #if DEBUG
    /// デバッグメニュー画面
    case debugMenu
    #endif

}

extension EnvironmentValues {

    @Entry var settingNavigationPath = AppNavigationPath<SettingRoute>()

}
