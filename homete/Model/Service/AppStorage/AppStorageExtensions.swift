//
//  AppStorageExtensions.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import SwiftUI

// MARK: - Data型の拡張

extension SwiftUI.AppStorage where Value == Data? {
    
    init(key: AppStorageOptionalDataKey) {
        
        self.init(key.rawValue)
    }
}

enum AppStorageOptionalDataKey: String {
    
    /// アーカイブされたP2P通信での自身のID
    case archivedPeerIDDataKey
}

// MARK: - String型の拡張

extension SwiftUI.AppStorage where Value == String {
    
    init(wrappedValue: String, key: AppStorageStringKey) {
        
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }
}

enum AppStorageStringKey: String {
    
    /// 同居人ID
    case cohabitantId
}

// MARK: - Preview用のDIヘルパー

struct InjectAppStorageWithPreviewModifier: ViewModifier {
    private let userDefaults: UserDefaults
    
    init(_ suiteName: String) {
        
        // swiftlint:disable:next force_unwrapping
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func body(content: Content) -> some View {
        content
            .defaultAppStorage(userDefaults)
    }
}

extension View {
    
    func injectAppStorageWithPreview(_ suiteName: String) -> some View {
        self.modifier(InjectAppStorageWithPreviewModifier(suiteName))
    }
}
