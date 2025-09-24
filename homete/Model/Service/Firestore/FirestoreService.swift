//
//  FirestoreService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Combine
import FirebaseFirestore

struct FirestoreListener {
    let continuation: AsyncStream<Any>.Continuation
    let listener: ListenerRegistration
}

final actor FirestoreService {
    
    static let shared = FirestoreService()
    private let firestore = Firestore.firestore()
    private var listeners: [AnyHashable: FirestoreListener] = [:]
    
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
    
    func addSnapshotListener<T: Encodable>(id: AnyHashable) -> AsyncStream<[T]> {
        
        let (stream, continuation) = AsyncStream<[T]>.makeStream(bufferingPolicy: .bufferingNewest(10))
        
        firestore.houseworkListRef(id: "")
            .whereField("indexedDate", arrayContains: ["2025-09-15"])
            .addSnapshotListener { snapshots, error in
                
            }
        return stream
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
 
    /// 指定日付の家事の参照を取得する
    func houseworkRef(id: String, indexedDate: String) -> DocumentReference {
        
        return self.cohabitantRef(id: id)
            .collection(CollectionPath.houseworks.rawValue)
            .document(indexedDate)
    }
    
    /// 指定日付の家事の参照を取得する
    func dailyHouseworksRef(id: String, indexedDate: String) -> CollectionReference {
        
        return self.cohabitantRef(id: id)
            .collection(CollectionPath.houseworks.rawValue)
            .document(indexedDate)
            .collection(CollectionPath.dailyHouseworks.rawValue)
    }
}

enum CollectionPath: String {
    
    case account = "Account"
    case cohabitant = "Cohabitant"
    case houseworks = "Houseworks"
    case dailyHouseworks = "DailyHouseworks"
}
