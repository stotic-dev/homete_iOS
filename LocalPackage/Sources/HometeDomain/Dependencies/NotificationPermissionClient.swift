//
//  NotificationPermissionClient.swift
//  LocalPackage
//

public struct NotificationPermissionClient: Sendable {

    /// プッシュ通知の権限をリクエストする
    /// - Returns: 権限が許可されているかどうか
    /// - Note: OSの仕様上、ダイアログが実際に表示されるのは権限が未決定のときのみ。
    ///         決定済みの場合はダイアログを出さずに現在の許可状態が返る
    public let requestAuthorization: @Sendable () async -> Bool
    /// リモート通知（APNs）のデバイストークン登録を要求する
    public let registerForRemoteNotifications: @Sendable () async -> Void

    public init(
        requestAuthorization: @Sendable @escaping () async -> Bool = { false },
        registerForRemoteNotifications: @Sendable @escaping () async -> Void = {}
    ) {
        self.requestAuthorization = requestAuthorization
        self.registerForRemoteNotifications = registerForRemoteNotifications
    }

}

public extension NotificationPermissionClient {

    static let previewValue: NotificationPermissionClient = .init()

}
