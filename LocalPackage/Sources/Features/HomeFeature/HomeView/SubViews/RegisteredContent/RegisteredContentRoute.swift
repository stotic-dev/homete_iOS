//
//  RegisteredContentRoute.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeUI
import SwiftUI

enum RegisteredContentRoute: Hashable {

    /// 未完了家事一覧画面
    case incompleteHouseworkList

}

extension EnvironmentValues {

    @Entry var registeredContentNavigationPath = AppNavigationPath<RegisteredContentRoute>()

}
