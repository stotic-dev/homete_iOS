//
//  AnalyticsClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AnalyticsClient: Sendable {

    public let setId: @Sendable (String) -> Void
    public let log: @Sendable (AnalyticsEvent) -> Void

    public init(
        setId: @Sendable @escaping (String) -> Void = { _ in },
        log: @Sendable @escaping (AnalyticsEvent) -> Void = { _ in }
    ) {

        self.setId = setId
        self.log = log
    }
}

public extension AnalyticsClient {

    static let previewValue = AnalyticsClient()
}
