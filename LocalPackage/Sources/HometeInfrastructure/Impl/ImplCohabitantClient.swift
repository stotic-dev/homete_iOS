//
//  ImplCohabitantClient.swift
//

import FirebaseFirestore
import HometeDomain

extension CohabitantClient {

    static let liveValue: CohabitantClient = .init { data in

        try await FirestoreService.shared.insertOrUpdate(data: data) {

            return $0.cohabitantRef(id: data.id)
        }
    } addSnapshotListener: { listenerId, cohabitantId in

        return await FirestoreService.shared.addSnapshotListener(id: listenerId) {
            $0.collection(path: .cohabitant)
                .whereField(CohabitantData.idField, isEqualTo: cohabitantId)
        }
    } removeSnapshotListener: { listenerId in

        await FirestoreService.shared.removeSnapshotListener(id: listenerId)
    }
}
