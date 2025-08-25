//
//  AppStorage.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
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
