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
    /// プッシュ通知の権限が決定済み（許可・拒否のいずれか）かどうかを返す
    /// - Note: ダイアログを出さずに状態だけを知りたい場面で使う
    public let isAuthorizationDetermined: @Sendable () async -> Bool

    public init(
        requestAuthorization: @Sendable @escaping () async -> Bool = { false },
        registerForRemoteNotifications: @Sendable @escaping () async -> Void = {},
        isAuthorizationDetermined: @Sendable @escaping () async -> Bool = { false }
    ) {
        self.requestAuthorization = requestAuthorization
        self.registerForRemoteNotifications = registerForRemoteNotifications
        self.isAuthorizationDetermined = isAuthorizationDetermined
    }

}

public extension NotificationPermissionClient {

    static let previewValue: NotificationPermissionClient = .init()

}
