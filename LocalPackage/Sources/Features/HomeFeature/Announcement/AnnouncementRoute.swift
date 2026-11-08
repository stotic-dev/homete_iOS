//
//  AnnouncementRoute.swift
//  LocalPackage
//

import HomeFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

/// お知らせの一覧から開く画面
enum AnnouncementRoute: Hashable {

    /// お知らせの詳細画面
    case detail(Announcement)

}

extension EnvironmentValues {

    @Entry var announcementNavigationPath = AppNavigationPath<AnnouncementRoute>()

}
