//
//  DailyCompletionReminderTrigger.swift
//  LocalPackage
//

/// ふりかえり通知を予約したきっかけ
/// - Note: 1日1回の制限を外している間（デバッグ用）は、どの経路で予約されたかを確かめられるよう通知の本文に載せる
public enum DailyCompletionReminderTrigger: Sendable {

    /// アプリで家事の一覧を購読している間に、今日の完了家事が見つかった
    case houseworkList
    /// アプリが起動していない間に、同居人からサイレント通知が届いた
    case silentNotification
    /// Notification Service Extensionが、古いアプリからの完了通知を受け取った
    case notificationServiceExtension
    /// 通知の設定を変えたので予約し直した
    case settingChanged

    /// 通知の本文に載せる名前
    var debugLabel: String {
        switch self {
        case .houseworkList:
            "家事一覧"
        case .silentNotification:
            "サイレント通知"
        case .notificationServiceExtension:
            "通知拡張"
        case .settingChanged:
            "設定変更"
        }
    }

}
