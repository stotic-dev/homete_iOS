//
//  AccountInfoClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import FirebaseFirestore

struct AccountInfoClient {
    
    let insertOrUpdate: @Sendable (Account) async throws -> Void
    let fetch: @Sendable (String) async throws -> Account?
}

extension AccountInfoClient: DependencyClient {
    
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
    
    static let previewValue: AccountInfoClient = .init(insertOrUpdate: { _ in },
                                                       fetch: { _ in .empty })
}
