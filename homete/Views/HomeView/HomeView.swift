//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
    
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    var body: some View {
        ZStack {
            if cohabitantId.isEmpty {
                NotRegisteredContent()
            }
            else {
                RegisteredContent()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationBarButton(label: .settings) {
                    rootNavigationPath.showSettingView()
                }
            }
        }
    }
}

#Preview("未登録時") {
    var userDefaults: UserDefaults {
        // swiftlint:disable:next force_unwrapping
        let userDefaults = UserDefaults(suiteName: "preview")!
        userDefaults.removeObject(forKey: AppStorageStringKey.cohabitantId.rawValue)
        return userDefaults
    }
    NavigationStack {
        HomeView()
            .defaultAppStorage(userDefaults)
    }
}

#Preview("登録時") {
    var userDefaults: UserDefaults {
        // swiftlint:disable:next force_unwrapping
        let userDefaults = UserDefaults(suiteName: "preview")!
        userDefaults.set("test", forKey: AppStorageStringKey.cohabitantId.rawValue)
        return userDefaults
    }
    NavigationStack {
        HomeView()
            .defaultAppStorage(userDefaults)
    }
}
