//
//  CollectionPath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/04.
//

import FirebaseFirestore

enum CollectionPath: String {
    
    case account = "Account"
    case cohabitant = "Cohabitant"
    case houseworks = "Houseworks"
    case dailyHouseworks = "DailyHouseworks"
}

extension Firestore {
    
    func collection(path: CollectionPath) -> CollectionReference {
        
        return self.collection(path.rawValue)
    }
}
