//
//  ImplAccountInfoClient.swift
//

import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension AccountInfoClient {

    static let liveValue: AccountInfoClient = .init { account in
        try await FirestoreService.shared.insertOrUpdate(data: account) {
            $0.accountRef(id: account.id)
        }
    } fetch: { id in
        try await FirestoreService.shared.fetch {
            $0.accountRef(id: id)
        }
    } addSnapshotListener: { listenerId, accountId in
        await FirestoreService.shared.addSnapshotListener(id: listenerId) {
            $0.accountRef(id: accountId)
        }
    } removeSnapshotListener: { listenerId in
        await FirestoreService.shared.removeSnapshotListener(id: listenerId)
    }

}
