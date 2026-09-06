//
//  NotificationPermissionAnalyticsAction.swift
//  LocalPackage
//

/// プッシュ通知の権限リクエストの起点画面
public enum NotificationPermissionAnalyticsStep: String, Equatable, Sendable {

    /// オンボーディング中の案内
    case onboarding
    /// 設定画面からの案内
    case setting

}

/// プッシュ通知の権限リクエストに関する行動
/// - Note: GA4はプロパティごとに定義できるイベント名の数に上限があるため、行動ごとにイベント名を増やさず
///         `notification_permission`イベント1つにまとめ、この型が生成するパラメータで区別する。
///         オンボーディング・設定画面の両方の導線を同じイベントで比較できるようにする
public enum NotificationPermissionAnalyticsAction: Equatable, Sendable {

    /// 通知の権限をリクエストした
    /// - Parameter isGranted: 権限が許可されたかどうか。すでに可否が決まっており設定Appへの遷移のみ行った場合はnil
    case permissionRequested(step: NotificationPermissionAnalyticsStep, isGranted: Bool?)
    /// 権限をリクエストせずにスキップした
    case skipped(step: NotificationPermissionAnalyticsStep)

}

extension NotificationPermissionAnalyticsAction {

    /// `notification_permission`イベントに載せるパラメータ
    /// - Note: `step`と`action`は全ケースで送り、結果を伴う行動のみ`result`を追加する
    var parameters: [String: String] {
        var parameters = ["step": step, "action": action]
        if let result {
            parameters["result"] = result
        }
        return parameters
    }

}

private extension NotificationPermissionAnalyticsAction {

    var step: String {
        switch self {
        case let .permissionRequested(step, _):
            step.rawValue

        case let .skipped(step):
            step.rawValue
        }
    }

    var action: String {
        switch self {
        case .permissionRequested:
            "permission_requested"

        case .skipped:
            "skipped"
        }
    }

    /// 行動の結果。GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
    var result: String? {
        switch self {
        case let .permissionRequested(_, isGranted):
            isGranted.map { $0 ? "granted" : "denied" }

        case .skipped:
            nil
        }
    }

}
