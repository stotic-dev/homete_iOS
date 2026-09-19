//
//  AnalyticsClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AnalyticsClient: Sendable {

    public let setId: @Sendable (String) -> Void
    /// ユーザーIDを未設定に戻す
    /// - Note: ログアウト・退会後もSDK側にIDが残るため、明示的に消さないと以降のイベントが前ユーザーに紐づく
    public let clearId: @Sendable () -> Void
    public let setUserProperty: @Sendable (AnalyticsUserProperty) -> Void
    public let log: @Sendable (AnalyticsEvent) -> Void

    public init(
        setId: @Sendable @escaping (String) -> Void = { _ in },
        clearId: @Sendable @escaping () -> Void = {},
        setUserProperty: @Sendable @escaping (AnalyticsUserProperty) -> Void = { _ in },
        log: @Sendable @escaping (AnalyticsEvent) -> Void = { _ in }
    ) {
        self.setId = setId
        self.clearId = clearId
        self.setUserProperty = setUserProperty
        self.log = log
    }

}

public extension AnalyticsClient {

    static let previewValue = AnalyticsClient()

}
