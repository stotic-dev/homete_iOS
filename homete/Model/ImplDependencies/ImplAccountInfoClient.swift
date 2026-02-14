//
//  AccountInfoClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import FirebaseFirestore
import HometeDomain

extension AccountInfoClient {
    
    private static let collectionPath = "Account"
    private static let primaryKey = "id"
    
    static let liveValue: AccountInfoClient = .init { account in
        
        try await FirestoreService.shared.insertOrUpdate(data: account) {
            
            return $0.accountRef(id: account.id)
        }
    } fetch: { id in
        
        return try await FirestoreService.shared.fetch {
            
            return $0.accountRef(id: id)
        }
    }
}
