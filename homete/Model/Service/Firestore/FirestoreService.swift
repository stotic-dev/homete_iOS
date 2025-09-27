//
//  FirestoreService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Combine
import FirebaseFirestore

protocol FirestoreListenerStorerable<Element> {
    associatedtype Element
    var continuation: AsyncStream<Element>.Continuation { get }
    var listener: any ListenerRegistration { get }
    func remove()
}

struct FirestoreListener<Element>: FirestoreListenerStorerable {
    let continuation: AsyncStream<Element>.Continuation
    let listener: any ListenerRegistration
    
    func remove() {
        
        continuation.finish()
        listener.remove()
    }
}

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
        
        try predicate(firestore).setData(from: data, merge: true)
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
                    return
                }
                guard let snapshots else { return }
                let convertedValues = snapshots.documents.compactMap { try? $0.data(as: Output.self) }
                continuation.yield(convertedValues)
            }
        listeners[id] = FirestoreListener(continuation: continuation, listener: listener)
        return stream
    }
    
    func removeSnapshotListner(id: String) {
        
        let listener = listeners[id]
        listener?.remove()
    }
}

extension Firestore {
    
    /// アカウントの参照を取得する
    func accountRef(id: String) -> DocumentReference {
        
        return self
            .collection(CollectionPath.account.rawValue)
            .document(id)
    }
    
    /// 同居人の参照を取得する
    func cohabitantRef(id: String) -> DocumentReference {
        
        return self
            .collection(CollectionPath.cohabitant.rawValue)
            .document(id)
    }
    
    /// 家事コレクションの参照を取得する
    func houseworkListRef(id: String) -> CollectionReference {
        
        return self.cohabitantRef(id: id)
            .collection(CollectionPath.houseworks.rawValue)
    }
}

enum CollectionPath: String {
    
    case account = "Account"
    case cohabitant = "Cohabitant"
    case houseworks = "Houseworks"
    case dailyHouseworks = "DailyHouseworks"
}
