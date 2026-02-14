//
//  AppNavigationElement.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import HometeDomain

enum AppNavigationElement: Hashable {
    /// 家事詳細画面
    case houseworkDetail(item: HouseworkItem)
}
