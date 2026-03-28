//
//  HouseworkBoardRoute.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

enum HouseworkBoardRoute: Hashable {
    /// 家事詳細画面
    case houseworkDetail(HouseworkItem)
}

extension EnvironmentValues {
    @Entry var houseworkBoardNavigationPath = AppNavigationPath<HouseworkBoardRoute>()
}
