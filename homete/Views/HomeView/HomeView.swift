//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
        
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    @State var navigationPath = CustomNavigationPath<HomeNavigationPathElement>(path: [])
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                if cohabitantId.isEmpty {
                    NotRegisteredContent()
                }
                else {
                    RegisteredContent()
                }
            }
            .environment(\.homeNavigationPath, navigationPath)
            .navigationDestination(for: HomeNavigationPathElement.self) { element in
                element.destination()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings) {
                        navigationPath.push(.settings)
                    }
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
    HomeView()
        .defaultAppStorage(userDefaults)
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
