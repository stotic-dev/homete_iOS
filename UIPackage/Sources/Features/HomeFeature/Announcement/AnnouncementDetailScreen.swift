//
//  AnnouncementDetailScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HomeFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

/// お知らせの詳細画面（一覧から開く）
struct AnnouncementDetailScreen: View {

    @Environment(\.openURL) var openURL

    let announcement: Announcement

    var body: some View {
        AnnouncementDetailView(announcement: announcement) { url in
            openURL(url)
        }
        .trackScreenView(.announcementDetail)
    }

}
