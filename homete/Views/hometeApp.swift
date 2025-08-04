//
//  hometeApp.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        #if DEBUG
        guard let devPlistFilePath = (Bundle.main.url(forResource: "GoogleService-Info-dev", withExtension: "plist")?.path()),
              let firebaseOption = FirebaseOptions(contentsOfFile: devPlistFilePath) else { return true }
        FirebaseApp.configure(options: firebaseOption)
        #else
        FirebaseApp.configure()
        #endif
        
        return true
    }
}

@main
struct hometeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.appDependencies) var appDependencies
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.accountStore, .init(appDependencies: appDependencies))
        }
    }
}
