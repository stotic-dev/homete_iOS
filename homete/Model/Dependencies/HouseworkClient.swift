//
//  HouseworkClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import FirebaseFirestore

struct HouseworkClient {
    
    let registerNewItem: @Sendable (HouseworkItem, String) async throws -> Void
    let snapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String,
        _ anchorDate: Date,
        _ offset: Int
    ) async -> AsyncStream<[HouseworkItem]>
    let removeListener: @Sendable (_ id: String) async -> Void
}

extension HouseworkClient: DependencyClient {
        
    static let liveValue = HouseworkClient { item, cohabitantId in
        
        try await FirestoreService.shared.insertOrUpdate(data: item) {
            
            return $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } snapshotListener: { id, cohabitantId, anchorDate, offset in
        
        let targetDateList = makeSymmetricDateWindow(
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
    
    static let previewValue = HouseworkClient(
        registerNewItem: { _, _ in },
        snapshotListener: { _, _, _, _ in .makeStream().stream },
        removeListener: { _ in }
    )
    
    static func makeSymmetricDateWindow(
        anchorDate: Date,
        offsetDays: Int,
        calendar: Calendar
    ) -> [String] {
        
        let base = calendar.startOfDay(for: anchorDate)
        guard offsetDays >= 0 else {
            
            return [base.formatted(Date.FormatStyle.firestoreDateFormatStyle)]
        }
        // -offset ... +offset の範囲を列挙
        return (-offsetDays...offsetDays).compactMap { delta in
            
            let date = calendar.date(byAdding: .day, value: delta, to: base)
            return date?.formatted(Date.FormatStyle.firestoreDateFormatStyle)
        }
    }
}
