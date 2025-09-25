//
//  FirestoreService.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import Combine
import FirebaseFirestore

struct FirestoreListener {
    let listener: any ListenerRegistration
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
    
    func addSnapshotListener(id: AnyHashable, predicate: (Firestore) -> Query) -> AnyPublisher<QuerySnapshot, any Error> {
        
        let publisher = PassthroughSubject<QuerySnapshot, any Error>()
        
        let listener = predicate(firestore)
            .addSnapshotListener { snapshots, error in
                
                if let error {
                    
                    publisher.send(completion: .failure(error))
                    return
                }
                guard let snapshots else { return }
                publisher.send(snapshots)
            }
        listeners[id] = .init(listener: listener)
        return publisher.eraseToAnyPublisher()
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
