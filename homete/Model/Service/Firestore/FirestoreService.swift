//
//  FirestoreService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import FirebaseFirestore

final actor FirestoreService {
    
    static let shared = FirestoreService()
    private let firestore = Firestore.firestore()
    private var listeners: [String: any FirestoreListenerStorerable] = [:]
    
    func fetch<T: Decodable>(predicate: (Firestore) -> Query) async throws -> [T] {
        
        return try await predicate(firestore)
            .getDocuments()
            .documents
            .map { try $0.data(as: T.self) }
    }
    
    func fetch<T: Decodable & Sendable>(predicate: (Firestore) -> DocumentReference) async throws -> T {
        
        return try await predicate(firestore).getDocument(as: T.self)
    }
    
    func insertOrUpdate<T: Encodable>(data: T, predicate: (Firestore) -> DocumentReference) throws {
        
        try predicate(firestore).setData(from: data, merge: false)
    }
    
    func delete(predicate: (Firestore) -> DocumentReference) async throws {
        
        try await predicate(firestore).delete()
    }
    
    func addSnapshotListener<Output>(
        id: String,
        predicate: (Firestore) -> Query
    ) -> AsyncStream<[Output]> where Output: Decodable {
        
        let (stream, continuation) = AsyncStream.makeStream(
            of: [Output].self,
            bufferingPolicy: .bufferingNewest(10)
        )
        let listener = predicate(firestore)
            .addSnapshotListener { snapshots, error in
                
                if let error {
                    
                    print("occurred error at fetchSnapshotListener(type: \(Output.self), error: \(error))")
                    return
                }
                
                guard let snapshots else { return }
                let convertedValues = snapshots.documents.compactMap { try? $0.data(as: Output.self) }
                continuation.yield(convertedValues)
            }
        
        listeners[id] = FirestoreListener(continuation: continuation, listener: listener)
        return stream
    }
    
    func removeSnapshotListener(id: String) {
        
        let listener = listeners[id]
        listener?.remove()
    }
}
