//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFirestore

struct HouseworkClient {
    
    let insertOrUpdateItem: @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void
    let snapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String,
        _ anchorDate: Date,
        _ offset: Int
    ) async -> AsyncStream<[HouseworkItem]>
    let removeListener: @Sendable (_ id: String) async -> Void
}

extension HouseworkClient: DependencyClient {
    
    init(
        insertOrUpdateItemHandler: @escaping @Sendable (_ item: HouseworkItem, _ cohabitantId: String) async throws -> Void = { _, _ in },
        snapshotListenerHandler: @escaping @Sendable (
            _ id: String,
            _ cohabitantId: String,
            _ anchorDate: Date,
            _ offset: Int
        ) async -> AsyncStream<[HouseworkItem]> = { _, _, _, _ in .makeStream().stream },
        removeListenerHandler: @escaping @Sendable (_ id: String) async -> Void = { _ in }
    ) {
        
        insertOrUpdateItem = insertOrUpdateItemHandler
        snapshotListener = snapshotListenerHandler
        removeListener = removeListenerHandler
    }
        
    static let liveValue = HouseworkClient { item, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: item) {
            
            return $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } snapshotListener: { id, cohabitantId, anchorDate, offset in
        
        let targetDateList = calcTargetPeriod(
            anchorDate: anchorDate,
            offsetDays: offset,
            calendar: Calendar.autoupdatingCurrent
        )
        
        return await FirestoreService.shared.addSnapshotListener(id: id) {
            
            return $0.houseworkListRef(id: cohabitantId)
                .whereField("indexedDate", in: targetDateList)
        }
    } removeListener: { id in
        
        await FirestoreService.shared.removeSnapshotListner(id: id)
    }
    
    static let previewValue = HouseworkClient()
}

private extension HouseworkClient {
    
    static func calcTargetPeriod(
        anchorDate: Date,
        offsetDays: Int,
        calendar: Calendar
    ) -> [String] {
        
        let base = calendar.startOfDay(for: anchorDate)
        guard offsetDays >= 0 else {
            
            return [base.formatted(Date.FormatStyle.houseworkDateFormatStyle)]
        }
        // -offset ... +offset の範囲を列挙
        return (-offsetDays...offsetDays).compactMap { delta in
            
            let date = calendar.date(byAdding: .day, value: delta, to: base)
            return date?.formatted(Date.FormatStyle.houseworkDateFormatStyle)
        }
    }
}
