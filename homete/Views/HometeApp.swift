//
//  HometeApp.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import FirebaseCore
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        // swiftlint:disable:next discouraged_optional_collection
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        #if DEBUG
        guard let devPlistFilePath = (
            Bundle.main.url(
                forResource: "GoogleService-Info-dev",
                withExtension: "plist"
            )?
                .path()
        ),
              let firebaseOption = FirebaseOptions(contentsOfFile: devPlistFilePath) else { return true }
        FirebaseApp.configure(options: firebaseOption)
        #else
        FirebaseApp.configure()
        #endif
        
        return true
    }
}

@main
struct HometeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.appDependencies) var appDependencies
    
    var body: some Scene {
        WindowGroup {
            RootView(
                accountAuthStore: .init(appDependencies: appDependencies),
                accountStore: .init(appDependencies: appDependencies)
            )
        }
    }
}
