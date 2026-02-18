//
//  CohabitantPushNotificationClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
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
