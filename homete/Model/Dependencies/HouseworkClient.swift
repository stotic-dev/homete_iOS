//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Combine
import FirebaseFirestore

struct HouseworkClient {
    
    let registerNewItem: @Sendable (HouseworkItem, String) async throws -> Void
//    let registerDailyHouseworkList: @Sendable (DailyHouseworkList, String) async throws -> Void
//    let snapshotListener: @Sendable (_ id: AnyHashable, _ cohabitantId: String) -> AnyPublisher<[DailyHouseworkList], any Error>
//    let removeListener: @Sendable (_ id: AnyHashable) -> Void
}

extension HouseworkClient: DependencyClient {
        
    static let liveValue = HouseworkClient { item, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: item) {
            
            return $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    }
//    } snapshotListener: { id, cohabitantId in
//        
//        // TODO: FirebaseのSnapshotListnerからAsyncStreamを返す
//        return FirestoreService.shared.addSnapshotListener(id: id) {
//            
//            return $0.houseworkListRef(id: cohabitantId)
//                .whereField("indexedDate", in: [])
//                
//        }
//        .map {
//            $0.documents.compactMap { $0.data(as: HouseworkItem.self) }
//        }
//    }
    
    static let previewValue = HouseworkClient(
        registerNewItem: { _, _ in },
//        snapshotListener: { _ in .makeStream().stream }
    )
}
