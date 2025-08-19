//
//  CohabitantClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/18.
//

import FirebaseFirestore

struct CohabitantData: Codable {
    
    let id: String
    let members: [String]
}

struct CohabitantClient {
    
    let register: @Sendable (CohabitantData) async throws -> Void
}

extension CohabitantClient: DependencyClient {
    
    private static let collectionPath = "Cohabitant"
    private static let primaryKey = "id"
    
    static let liveValue: CohabitantClient = .init { data in
        
        try await FirestoreService.shared.insertOrUpdate(data: data) {
            
            $0.collection(collectionPath).document(data.id)
        }
    }
    
    static let previewValue: CohabitantClient = .init { _ in }
}
