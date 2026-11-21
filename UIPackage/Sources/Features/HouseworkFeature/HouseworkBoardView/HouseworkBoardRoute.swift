//
//  HouseworkBoardRoute.swift
//  homete
//

import HometeDomainUI
import HometeDomain
import HometeUI
import HouseworkFeatureUI
import SwiftUI

enum HouseworkBoardRoute: Hashable {

    /// 家事詳細画面
    case houseworkDetail(HouseworkBoardItem)

}

extension EnvironmentValues {

    @Entry var houseworkBoardNavigationPath = AppNavigationPath<HouseworkBoardRoute>()

}
