//
//  ImplCohabitantPushNotificationClient.swift
//

import FirebaseFunctions
import HometeDomain

extension CohabitantPushNotificationClient {

    static let liveValue: CohabitantPushNotificationClient = .init { id, content in
        _ = try await Functions.functions()
            .httpsCallable("notifyothercohabitants")
            .call([
                "cohabitantId": id,
                "title": content.title,
                "body": content.message
            ])
    }
}
