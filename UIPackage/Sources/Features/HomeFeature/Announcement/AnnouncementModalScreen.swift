//
//  AnnouncementModalScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HomeFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

/// 起動時に出すお知らせのシート
/// - Note: 既読にするのは、閉じたことを受け取る出す側（`HomeView`）で行う。下へのスワイプで閉じたときも既読にするため
struct AnnouncementModalScreen: View {

    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    let announcement: Announcement

    var body: some View {
        NavigationStack {
            AnnouncementModalView(
                announcement: announcement,
                onTapLink: { url in openURL(url) },
                onTapClose: { dismiss() }
            )
        }
        .trackScreenView(.announcementModal)
    }

}
