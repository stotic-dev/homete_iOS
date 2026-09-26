//
//  ImplCohabitantPushNotificationClient.swift
//

import HometeDomain
import HometeInfrastructure

extension CohabitantPushNotificationClient {

    static let liveValue: CohabitantPushNotificationClient = .init(
        send: { id, content in
            let parameters: [String: Any] = [
                "cohabitantId": id,
                "title": content.title,
                "body": content.message,
            ]
            _ = try await FunctionsService.call("notifyothercohabitants", parameters: parameters)
        },
        sendSilent: { id, data in
            let parameters: [String: Any] = [
                "cohabitantId": id,
                "data": data,
                "silent": true,
            ]
            _ = try await FunctionsService.call("notifyothercohabitants", parameters: parameters)
        }
    )

}
