//
//  ImplDebugAuthClient.swift
//  LocalPackage
//

#if DEBUG

import FirebaseAuth
import HometeDomain
import HometeInfrastructure

extension DebugAuthClient {

    static let liveValue: DebugAuthClient = .init(
        revokeOwnRefreshTokens: {
            _ = try await FunctionsService.call("debugrevokerefreshtokens")
        },
        refreshIdToken: {
            guard let user = Auth.auth().currentUser else {
                throw DomainError.failAuth
            }
            _ = try await user.getIDTokenResult(forcingRefresh: true)
        }
    )

}

#endif
