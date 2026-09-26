//
//  NotificationService.swift
//  hometeNotificationService
//

import Foundation
import HometeDomain
import HometeLocalNotification
import UserNotifications

/// 同居人からの家事の完了通知を受け取ったときに、今日のふりかえり通知を予約する
///
/// アプリが起動していなくても、`mutable-content`付きの通知を受け取るとOSがこの拡張を起動する。
/// 受け取った通知の内容は書き換えず、そのまま表示する。
/// - Note: `didReceive`とOSからの`serviceExtensionTimeWillExpire`は別スレッドから呼ばれうるため、
///         保持する状態はロックで守る
final class NotificationService: UNNotificationServiceExtension, @unchecked Sendable {

    private let lock = NSLock()
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var originalContent: UNNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let content = request.content
        guard let data = HouseworkCompletedNotificationData(userInfo: content.userInfo) else {
            contentHandler(content)
            return
        }

        lock.withLock {
            self.contentHandler = contentHandler
            originalContent = content
        }

        Task {
            // 予約の完了を待ってから通知を渡す。先に渡すと拡張のプロセスが終了し、予約が失われうる
            let useCase = DailyCompletionReminderUseCase(client: .liveValue)
            await useCase.handleCompleted(
                data,
                trigger: .notificationServiceExtension,
                now: .now,
                calendar: .autoupdatingCurrent
            )
            self.deliverOriginalContent()
        }
    }

    override func serviceExtensionTimeWillExpire() {
        deliverOriginalContent()
    }

}

private extension NotificationService {

    /// 受け取った通知をそのまま表示に回す。2回目以降の呼び出しは何もしない
    func deliverOriginalContent() {
        let pending = lock.withLock {
            defer {
                contentHandler = nil
                originalContent = nil
            }
            return contentHandler.flatMap { handler in
                originalContent.map { (handler, $0) }
            }
        }
        guard let pending else { return }

        pending.0(pending.1)
    }

}
