//
//  AppStorage.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import Foundation

struct AppStorageClient {
    
    private let appStorage: AppStorage
    
    init(userDefaults: sending UserDefaults) {
        
        self.appStorage = .init(userDefaults: userDefaults)
    }
    
    func callAsFunction() -> AppStorage {
        
        return appStorage
    }
}

extension AppStorageClient: DependencyClient {
    
    static let liveValue: AppStorageClient = .init(userDefaults: .standard)
    
    // swiftlint:disable:next force_unwrapping
    static let previewValue: AppStorageClient = .init(userDefaults: .init(suiteName: "preview")!)
}
