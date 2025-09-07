//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFirestore

struct HouseworkClient {
    
    let registerNewItem: @Sendable (HouseworkItem, Date, String) async throws -> Void
    let registerDailyHouseworkList: @Sendable (DailyHouseworkList, String) async throws -> Void
}

extension HouseworkClient: DependencyClient {
        
    static let liveValue = HouseworkClient { item, indexedDate, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: item) {
            
            return $0
                .dailyHouseworksRef(id: cohabitantId, indexedDate: indexedDate)
                .document(item.id)
        }
    } registerDailyHouseworkList: { houseworkList, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: houseworkList.metaData) {
            
            return $0
                .houseworkRef(id: cohabitantId, indexedDate: houseworkList.indexedDate)
        }
        
        for item in houseworkList.items {
            
            try await FirestoreService.shared.insertOrUpdate(data: item) {
                
                return $0
                    .dailyHouseworksRef(id: cohabitantId, indexedDate: houseworkList.indexedDate)
                    .document(item.id)
            }
        }
    }
    
    static let previewValue = HouseworkClient(
        registerNewItem: { _, _, _ in },
        registerDailyHouseworkList: { _, _ in }
    )
}
