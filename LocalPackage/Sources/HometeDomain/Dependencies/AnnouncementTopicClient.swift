//
//  AnnouncementTopicClient.swift
//  LocalPackage
//

/// お知らせのPush通知を受け取るかどうかの設定と、FCMトピックの購読を扱うClient
/// - Note: トピックの購読は端末単位のため、設定も端末に保存する（アカウントには紐づけない）
public struct AnnouncementTopicClient: Sendable {

    /// お知らせの通知を受け取る設定かどうかを読み出す。未設定なら`true`
    public let loadIsEnabled: @Sendable () async -> Bool
    /// お知らせの通知を受け取るかどうかを保存する
    public let saveIsEnabled: @Sendable (Bool) async -> Void
    /// お知らせのトピックを購読する
    public let subscribe: @Sendable () async -> Void
    /// お知らせのトピックの購読をやめる
    public let unsubscribe: @Sendable () async -> Void

    public init(
        loadIsEnabled: @Sendable @escaping () async -> Bool = { true },
        saveIsEnabled: @Sendable @escaping (Bool) async -> Void = { _ in },
        subscribe: @Sendable @escaping () async -> Void = {},
        unsubscribe: @Sendable @escaping () async -> Void = {}
    ) {
        self.loadIsEnabled = loadIsEnabled
        self.saveIsEnabled = saveIsEnabled
        self.subscribe = subscribe
        self.unsubscribe = unsubscribe
    }

}

public extension AnnouncementTopicClient {

    static let previewValue: AnnouncementTopicClient = .init()

}
