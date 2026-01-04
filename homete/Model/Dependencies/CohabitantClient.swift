//
//  CohabitantClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/18.
//

import FirebaseFirestore

struct CohabitantClient {
    
    let register: @Sendable (CohabitantData) async throws -> Void
    let addSnapshotListener: @Sendable (
        _ listenerId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[CohabitantData]>
    let removeSnapshotListener: @Sendable (_ listenerId: String) async -> Void
    
    init(
        register: @Sendable @escaping (CohabitantData) async throws -> Void = { _ in },
        addSnapshotListener: @Sendable @escaping (
            _: String,
            _: String
        ) async -> AsyncStream<[CohabitantData]> = { _, _ in .init { nil } },
        removeSnapshotListener: @Sendable @escaping (_ listenerId: String) async -> Void = { _ in }
    ) {
        
        self.register = register
        self.addSnapshotListener = addSnapshotListener
        self.removeSnapshotListener = removeSnapshotListener
    }
}

extension CohabitantClient: DependencyClient {
        
    static let liveValue: CohabitantClient = .init { data in
        
        try await FirestoreService.shared.insertOrUpdate(data: data) {
            
            return $0.cohabitantRef(id: data.id)
        }
    } addSnapshotListener: { listenerId, cohabitantId in
        
        return await FirestoreService.shared.addSnapshotListener(id: listenerId) {
            $0.collection(path: .cohabitant)
                .whereField(CohabitantData.idField, isEqualTo: cohabitantId)
        }
    } removeSnapshotListener: { listenerId in
        
        await FirestoreService.shared.removeSnapshotListener(id: listenerId)
    }
    
    static let previewValue: CohabitantClient = .init()
}
