//
//  ImplHouseworkEntryHistoryClient.swift
//  LocalPackage
//

import HometeDomain
import HometeInfrastructure

extension HouseworkEntryHistoryClient {

    static let liveValue = HouseworkEntryHistoryClient(
        fetch: {
            try await HouseworkEntryHistoryService.fetch()
        },
        save: { list in
            try await HouseworkEntryHistoryService.save(list)
        }
    )

}
