//
//  ImplCohabitantPushNotificationClient.swift
//

import HometeDomain
import HometeInfrastructure

extension CohabitantPushNotificationClient {

    static let liveValue: CohabitantPushNotificationClient = .init { id, content in
        _ = try await FunctionsService.call("notifyothercohabitants", parameters: [
            "cohabitantId": id,
            "title": content.title,
            "body": content.message,
        ])
    }

}
