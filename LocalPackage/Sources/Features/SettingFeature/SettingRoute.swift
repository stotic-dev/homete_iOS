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

}

extension EnvironmentValues {

    @Entry var settingNavigationPath = AppNavigationPath<SettingRoute>()

}
