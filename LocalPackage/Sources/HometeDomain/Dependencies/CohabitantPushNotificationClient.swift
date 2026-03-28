//
//  CohabitantPushNotificationClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

public struct CohabitantPushNotificationClient: Sendable {
    public let send: @Sendable (_ id: String, _ content: PushNotificationContent) async throws -> Void

    public init(send: @Sendable @escaping (_ id: String, _ content: PushNotificationContent) async throws -> Void) {
        self.send = send
    }
}

public extension CohabitantPushNotificationClient {

    static let previewValue: CohabitantPushNotificationClient = .init { _, _ in }
}
