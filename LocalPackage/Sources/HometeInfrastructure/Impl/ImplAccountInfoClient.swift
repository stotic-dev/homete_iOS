//
//  ImplAccountInfoClient.swift
//

import FirebaseFirestore
import HometeDomain

extension AccountInfoClient {

    static let liveValue: AccountInfoClient = .init { account in

        try await FirestoreService.shared.insertOrUpdate(data: account) {

            return $0.accountRef(id: account.id)
        }
    } fetch: { id in

        return try await FirestoreService.shared.fetch {

            return $0.accountRef(id: id)
        }
    }
}
