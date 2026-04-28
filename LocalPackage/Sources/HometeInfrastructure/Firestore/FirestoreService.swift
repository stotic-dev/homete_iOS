//
//  FirestoreService.swift
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

    /// クエリに一致するドキュメントをバッチ削除する
    func deleteDocuments(predicate: (Firestore) -> Query) async throws {

        let documents = try await predicate(firestore).getDocuments().documents
        guard !documents.isEmpty else { return }
        let batch = firestore.batch()
        for document in documents {
            batch.deleteDocument(document.reference)
        }
        try await batch.commit()
    }

    /// Firestoreトランザクションを実行する（楽観的ロックに使用）
    func runTransaction(_ updateBlock: @escaping (Transaction) throws -> Void) async throws {

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            firestore.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    try updateBlock(transaction)
                } catch {
                    errorPointer?.pointee = error as NSError
                }
                return nil
            }, completion: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
