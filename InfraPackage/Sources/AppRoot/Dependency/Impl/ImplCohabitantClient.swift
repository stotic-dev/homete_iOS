//
//  ImplCohabitantClient.swift
//

import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension CohabitantClient {

    static let liveValue: CohabitantClient = .init { listenerId, cohabitantId in
        await FirestoreService.shared.addSnapshotListener(id: listenerId) {
            $0.cohabitantRef(id: cohabitantId)
        }
    } removeSnapshotListener: { listenerId in
        await FirestoreService.shared.removeSnapshotListener(id: listenerId)
    }

}
