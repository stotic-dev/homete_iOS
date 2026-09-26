//
//  ImplCohabitantPushNotificationClient.swift
//

import HometeDomain
import HometeInfrastructure

extension CohabitantPushNotificationClient {

    static let liveValue: CohabitantPushNotificationClient = .init { id, content in
        var parameters: [String: Any] = [
            "cohabitantId": id,
            "title": content.title,
            "body": content.message,
        ]
        // dataを付けた通知だけ、受け取った端末でNotification Service Extensionが起動する
        if !content.data.isEmpty {
            parameters["data"] = content.data
        }
        _ = try await FunctionsService.call("notifyothercohabitants", parameters: parameters)
    }

}
