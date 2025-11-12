//
//  CohabitantPushNotificationClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

import FirebaseFunctions

struct CohabitantPushNotificationClient {
    let send: @Sendable (_ id: String, _ content: PushNotificationContent) async throws -> Void
}

extension CohabitantPushNotificationClient: DependencyClient {
    
    static let liveValue: CohabitantPushNotificationClient = .init { id, content in
        _ = try await Functions.functions()
            .httpsCallable("notifyothercohabitants")
            .call([
                "cohabitantId": id,
                "title": content.title,
                "body": content.message
            ])
    }
    
    static let previewValue: CohabitantPushNotificationClient = .init { _, _ in }
}
