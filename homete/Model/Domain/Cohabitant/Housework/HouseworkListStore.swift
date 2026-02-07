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
    
    private(set) var items: StoredAllHouseworkList
    private var cohabitantId: String
    
    private let houseworkClient: HouseworkClient
    private let cohabitantPushNotificationClient: CohabitantPushNotificationClient
        
    private let houseworkObserveKey = "houseworkObserveKey"
    
    init(
        houseworkClient: HouseworkClient = .previewValue,
        cohabitantPushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        items: [DailyHouseworkList] = [],
        cohabitantId: String = ""
    ) {
        
        self.houseworkClient = houseworkClient
        self.cohabitantPushNotificationClient = cohabitantPushNotificationClient
        self.items = .init(value: items)
        self.cohabitantId = cohabitantId
    }
    
    func loadHouseworkList(currentTime: Date, cohabitantId: String, calendar: Calendar) async {
        
        self.cohabitantId = cohabitantId
        
        guard !cohabitantId.isEmpty else {
            
            await clear()
            return
        }
        
        await houseworkClient.removeListener(houseworkObserveKey)
        
        let houseworkListStream = await houseworkClient.snapshotListener(
            houseworkObserveKey,
            cohabitantId,
            currentTime,
            3
        )
        
        Task {
            
            for await currentItems in houseworkListStream {
                
                items = StoredAllHouseworkList.makeMultiDateList(
                    items: currentItems,
                    calendar: calendar
                )
            }
        }
    }
    
    func register(_ newItem: HouseworkItem) async throws {
        
        try await houseworkClient.insertOrUpdateItem(newItem, cohabitantId)
        
        Task.detached {
            
            let notificationContent = PushNotificationContent.addNewHouseworkItem(newItem.title)
            try await self.cohabitantPushNotificationClient.send(self.cohabitantId, notificationContent)
        }
    }
    
    func requestReview(target: HouseworkItem, now: Date, executor: String) async throws {
        
        guard let targetItem = items.item(target) else {
            
            preconditionFailure("Not found target item(\(target))")
        }
        
        let updatedItem = targetItem.updatePendingApproval(at: now, changer: executor)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        
        Task.detached {
            
            let notificationContent = PushNotificationContent(
                title: "確認が必要な家事があります",
                message: "問題なければ「\(updatedItem.title)」の完了に感謝を伝えましょう！"
            )
            try await self.cohabitantPushNotificationClient.send(self.cohabitantId, notificationContent)
        }
    }
    
    func approved(target: HouseworkItem, now: Date, reviwer: Account, comment: String) async throws {
        
        guard let targetItem = items.item(target) else {
            
            preconditionFailure("Not found target item(\(target))")
        }
        
        let updatedItem = targetItem.updateApproved(at: now, reviewer: reviwer.id, comment: comment)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        
        Task.detached {
            
            let notificationContent = PushNotificationContent.approvedMessage(
                reviwerName: reviwer.userName,
                houseworkTitle: target.title,
                comment: comment
            )
            try await self.cohabitantPushNotificationClient.send(self.cohabitantId, notificationContent)
        }
    }
    
    func rejected(target: HouseworkItem, now: Date, reviwer: Account, comment: String) async throws {
        
        guard let targetItem = items.item(target) else {
            
            preconditionFailure("Not found target item(\(target))")
        }
        
        let updatedItem = targetItem.updateRejected(at: now, reviewer: reviwer.id, comment: comment)
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
        
        Task.detached {
            
            let notificationContent = PushNotificationContent.rejectedMessage(
                reviwerName: reviwer.userName,
                houseworkTitle: target.title,
                comment: comment
            )
            try await self.cohabitantPushNotificationClient.send(self.cohabitantId, notificationContent)
        }
    }
    
    func returnToIncomplete(target: HouseworkItem, now: Date) async throws {
        
        guard let targetItem = items.item(target) else {
            
            preconditionFailure("Not found target item(\(target))")
        }
        
        let updatedItem = targetItem.updateIncomplete()
        try await houseworkClient.insertOrUpdateItem(updatedItem, cohabitantId)
    }
    
    func remove(_ target: HouseworkItem) async throws {
        
        try await houseworkClient.removeItem(target, cohabitantId)
    }
}

private extension HouseworkListStore {
    
    func clear() async {
        
        await houseworkClient.removeListener(houseworkObserveKey)
        items.removeAll()
    }
}
