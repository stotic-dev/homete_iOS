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
        let devPlistFilePath = (Bundle.main.url(forResource: "GoogleService-Info-dev", withExtension: "plist")?.path())!
        FirebaseApp.configure(options: .init(contentsOfFile: devPlistFilePath)!)
        #else
        FirebaseApp.configure()
        #endif
        
        return true
    }
}

@main
struct hometeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
