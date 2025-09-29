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
}
