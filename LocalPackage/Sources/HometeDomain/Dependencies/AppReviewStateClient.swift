//
//  AppReviewStateClient.swift
//  LocalPackage
//

/// アプリの評価のリクエストに使う記録（`AppReviewState`）を永続化するClient
/// - Note: 端末ごとの記録でよいため、Firestoreには持たない。
///         記録は短い間隔で続けて更新されるため、非同期にすると書き込みの順番が入れ替わり、
///         古い記録で上書きされることがある。呼び出し側のアクター上で同期的に読み書きする
public struct AppReviewStateClient: Sendable {

    /// 記録を読み出す。一度も保存していない場合は`nil`
    public let load: @Sendable () -> AppReviewState?
    /// 記録を保存する
    public let save: @Sendable (AppReviewState) -> Void

    public init(
        load: @Sendable @escaping () -> AppReviewState? = { nil },
        save: @Sendable @escaping (AppReviewState) -> Void = { _ in }
    ) {
        self.load = load
        self.save = save
    }

}

public extension AppReviewStateClient {

    static let previewValue: AppReviewStateClient = .init()

}
