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
    
    static let collectionPath = "Account"
    static let primaryKey = "id"
    
    static let liveValue: AccountInfoClient = .init { account in
        
        try Firestore.firestore().collection(collectionPath).document(account.id).setData(from: account)
    } fetch: { id in
        
        let snapshots = try await Firestore.firestore()
            .collection(collectionPath)
            .whereField(primaryKey, isEqualTo: id)
            .getDocuments()
        return try snapshots.documents.first?.data(as: Account.self)
    }
    
    
    static let previewValue: AccountInfoClient = .init(insertOrUpdate: { _ in },
                                                       fetch: { _ in .init(id: "", displayName: "") })
}
