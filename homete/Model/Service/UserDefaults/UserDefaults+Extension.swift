//
//  UserDefaults+Extension.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import Foundation

actor AppStorage {
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    func data(key: UserDefaultsDataObjectKey) -> Data? {
        
        return userDefaults.data(forKey: key.rawValue)
    }
    
    func setData(_ data: Data, key: UserDefaultsDataObjectKey) {
        
        userDefaults.setValue(data, forKey: key.rawValue)
    }
}

enum UserDefaultsDataObjectKey: String {
    
    case archivedPeerIDDataKey
}

extension AppStorage: DependencyClient {
    
    static let liveValue: AppStorage = .init(userDefaults: .standard)
    
    static let previewValue: AppStorage = .init(userDefaults: .init(suiteName: "preview")!)
}
