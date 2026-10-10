//
//  AppReviewStateClient.swift
//  LocalPackage
//

/// アプリの評価のリクエストに使う記録（`AppReviewState`）を永続化するClient
/// - Note: 端末ごとの記録でよいため、Firestoreには持たない
public struct AppReviewStateClient: Sendable {

    /// 記録を読み出す。一度も保存していない場合は`nil`
    public let load: @Sendable () async -> AppReviewState?
    /// 記録を保存する
    public let save: @Sendable (AppReviewState) async -> Void

    public init(
        load: @Sendable @escaping () async -> AppReviewState? = { nil },
        save: @Sendable @escaping (AppReviewState) async -> Void = { _ in }
    ) {
        self.load = load
        self.save = save
    }

}

public extension AppReviewStateClient {

    static let previewValue: AppReviewStateClient = .init()

}
