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
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
        
    private let houseworkObserveKey = "houseworkObserveKey"
    
    init(
        houseworkClient: HouseworkClient,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient,
        items: [DailyHouseworkList] = []
    ) {
        
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
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
    
    func register(_ newItem: HouseworkItem) async throws {
        
        try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)
        
        let notificationContent = PushNotificationContent(
            title: "新しい家事が登録されました",
            message: newItem.title
        )
        try await cohabitantPushNotificationClient.send(cohabitantId, notificationContent)
    }
    
    func requestReview(id: String, indexedDate: Date) async throws {
        
        guard let targetDateGroup = items.first(where: { $0.metaData.indexedDate == indexedDate }),
              let targetItem = targetDateGroup.items.first(where: { $0.id == id }) else {
            
            preconditionFailure("Not found target item(id: \(id), indexedDate: \(indexedDate))")
        }
        
        let updatedItem = targetItem.updateState(.pendingApproval)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        
        let notificationContent = PushNotificationContent(
            title: "確認が必要な家事があります",
            message: "問題なければ「\(updatedItem.title)」の完了に感謝を伝えましょう！"
        )
        try await cohabitantPushNotificationClient.send(cohabitantId, notificationContent)
    }
}
