//
//  ImplHouseworkClient.swift
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
                .whereField("indexedDate.value", in: targetDateList)
        }
    } removeListenerHandler: { id in

        await FirestoreService.shared.removeSnapshotListener(id: id)
    } fetchItemsHandler: { cohabitantId, from, to in

        return try await FirestoreService.shared.fetch {
            $0.houseworkListRef(id: cohabitantId)
                .whereField("indexedDate.value", isGreaterThanOrEqualTo: from)
                .whereField("indexedDate.value", isLessThanOrEqualTo: to)
        }
    }
}
