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

// MARK: - カスタムオブジェクト用の拡張

extension SwiftUI.AppStorage where Value : RawRepresentable, Value.RawValue == String {
    
    init(wrappedValue: Value, key: AppStorageCustomTypeKey) {
        
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }
}

enum AppStorageCustomTypeKey: String {
    
    /// 家事入力の履歴
    case houseworkEntryHistoryList
}

