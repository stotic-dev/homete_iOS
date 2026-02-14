//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFirestore
import HometeDomain

extension HouseworkClient {
    
    static let liveValue = HometeDomain.HouseworkClient { item, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: item) {
            
            return $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } removeItemHandler: { item, cohabitantId in
        
        try await FirestoreService.shared.delete {
            
            return $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in
        
        let targetDateList = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: anchorDate,
            offsetDays: offset,
            calendar: .autoupdatingCurrent
        )
        
        return await FirestoreService.shared.addSnapshotListener(id: id) {
            
            return $0.houseworkListRef(id: cohabitantId)
                .whereField("indexedDate", in: targetDateList)
        }
    } removeListenerHandler: { id in
        
        await FirestoreService.shared.removeSnapshotListener(id: id)
    }
}
