//
//  HouseworkListStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/27.
//

import SwiftUI

@MainActor
@Observable
final class HouseworkListStore {
    
    var cohabitantId = ""
    
    private(set) var items: [DailyHouseworkList]
    
    private let houseworkClient: HouseworkClient
        
    private let houseworkObserveKey = "houseworkObserveKey"
    
    init(houseworkClient: HouseworkClient, items: [DailyHouseworkList] = []) {
        
        self.houseworkClient = houseworkClient
        self.items = items
    }
    
    func loadHouseworkList(currentTime: Date, cohabitantId: String, calendar: Calendar) async {
        
        await houseworkClient.removeListener(houseworkObserveKey)
        
        let houseworkListStream = await houseworkClient.snapshotListener(
            houseworkObserveKey,
            cohabitantId,
            currentTime,
            3
        )
        for await currentItems in houseworkListStream {
            
            items = DailyHouseworkList.makeMultiDateList(
                items: currentItems,
                calendar: calendar
            )
        }
    }
    
    func clear() async {
        
        await houseworkClient.removeListener(houseworkObserveKey)
        items.removeAll()
    }
    
    func requestReview(id: String, indexedDate: Date) async throws {
        
        guard let targetDateGroup = items.first(where: { $0.metaData.indexedDate == indexedDate }),
              let targetItem = targetDateGroup.items.first(where: { $0.id == id }) else {
            
            preconditionFailure("Not found target item(id: \(id), indexedDate: \(indexedDate))")
        }
        
        let updatedItem = targetItem.updateState(.pendingApproval)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        
        // TODO: パートナーに承認依頼したことを通知する
    }
}
