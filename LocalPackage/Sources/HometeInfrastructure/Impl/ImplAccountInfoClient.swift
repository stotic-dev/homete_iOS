//
//  ImplAccountInfoClient.swift
//

import FirebaseFirestore
import HometeDomain

extension AccountInfoClient {

    static let liveValue: AccountInfoClient = .init { account in
        try await FirestoreService.shared.insertOrUpdate(data: account) {
            $0.accountRef(id: account.id)
        }
    } fetch: { id in
        try await FirestoreService.shared.fetch {
            $0.accountRef(id: id)
        }
    }

}
