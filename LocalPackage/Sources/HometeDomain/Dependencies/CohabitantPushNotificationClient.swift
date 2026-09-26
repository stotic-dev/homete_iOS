//
//  CohabitantPushNotificationClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/12.
//

public struct CohabitantPushNotificationClient: Sendable {

    public let send: @Sendable (_ id: String, _ content: PushNotificationContent) async throws -> Void
    /// 画面に表示しないサイレント通知を送る
    /// - Note: 受け取った端末のアプリをバックグラウンドで起こし、`data`を渡すためだけに使う。
    ///         OSの判断で遅れたり間引かれたりするため、届かなくても困らない用途に限る
    public let sendSilent: @Sendable (_ id: String, _ data: [String: String]) async throws -> Void

    public init(
        send: @Sendable @escaping (_ id: String, _ content: PushNotificationContent) async throws -> Void,
        sendSilent: @Sendable @escaping (_ id: String, _ data: [String: String]) async throws -> Void = { _, _ in }
    ) {
        self.send = send
        self.sendSilent = sendSilent
    }

}

public extension CohabitantPushNotificationClient {

    static let previewValue: CohabitantPushNotificationClient = .init { _, _ in }

}
