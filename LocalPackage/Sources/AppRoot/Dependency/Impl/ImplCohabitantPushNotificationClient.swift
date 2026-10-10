//
//  ImplCohabitantPushNotificationClient.swift
//

import HometeDomain
import HometeInfrastructure

extension CohabitantPushNotificationClient {

    static let liveValue: CohabitantPushNotificationClient = .init { id, content in
        // 文面はこの端末の言語で組み立てる。受け取った端末では、dataに載せた通知の種類から
        // Notification Service Extensionが受け取った側の言語で組み立て直す（古いアプリではこの文面のまま出る）
        let parameters: [String: Any] = [
            "cohabitantId": id,
            "title": content.title(),
            "body": content.body(),
            "data": content.payload,
        ]
        _ = try await FunctionsService.call("notifyothercohabitants", parameters: parameters)
    }

}
