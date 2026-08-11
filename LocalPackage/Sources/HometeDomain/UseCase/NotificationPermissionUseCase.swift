//
//  NotificationPermissionUseCase.swift
//  LocalPackage
//

public final class NotificationPermissionUseCase: Sendable {

    private let notificationPermissionClient: NotificationPermissionClient

    public init(notificationPermissionClient: NotificationPermissionClient) {
        self.notificationPermissionClient = notificationPermissionClient
    }

    /// プッシュ通知の権限をリクエストし、許可された場合はAPNsへのデバイス登録まで行う
    /// - Returns: 権限が許可されているかどうか
    /// - Note: 権限が拒否済み・許可済みの場合はダイアログが出ないため、着地のたびに呼び出しても問題ない
    @discardableResult
    public func request() async -> Bool {
        let isGranted = await notificationPermissionClient.requestAuthorization()
        guard isGranted else { return false }

        await notificationPermissionClient.registerForRemoteNotifications()
        return true
    }

}
