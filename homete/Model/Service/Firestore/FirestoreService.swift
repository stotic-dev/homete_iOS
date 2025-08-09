//
//  FirestoreService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import FirebaseFirestore

final actor FirestoreService {
    
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    func fetch<T: Decodable>(predicate: (Firestore) -> Query) async throws -> [T] {
        
        return try await predicate(db)
            .getDocuments()
            .documents
            .map { try $0.data(as: T.self) }
    }
    
    func insertOrUpdate<T: Encodable>(data: T, predicate: (Firestore) -> DocumentReference) throws {
        
        try predicate(db).setData(from: data, merge: true)
    }
}
