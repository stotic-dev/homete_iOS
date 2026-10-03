//
//  RemoteConfigClient.swift
//  LocalPackage
//

public struct RemoteConfigClient: Sendable {

    /// サーバーから最新の値を取得し、アプリから読める値に反映する
    public let fetchAndActivate: @Sendable () async throws -> Void
    /// コンソールで公開された変更を、アプリから読める値に反映してから通知する
    /// - Note: `minimumFetchInterval`に関係なく、公開から間を置かずに届く
    public let configUpdates: @Sendable () -> AsyncStream<Void>
    /// 反映済みの値を読む。一度も反映できていなければアプリ内デフォルト値を返す
    public let bool: @Sendable (RemoteConfigBoolKey) -> Bool
    /// 反映済みの値を読む。一度も反映できていなければアプリ内デフォルト値を返す
    public let string: @Sendable (RemoteConfigStringKey) -> String

    /// - Note: asyncクロージャをデフォルト引数に書くと、Xcode 26系でビルドしたテストを並列実行したときに
    ///         asyncフレームが壊れてクラッシュするため、`nil`を受けてinit本体で既定の実装を詰める
    public init(
        fetchAndActivate: (@Sendable () async throws -> Void)? = nil,
        configUpdates: @Sendable @escaping () -> AsyncStream<Void> = { AsyncStream { $0.finish() } },
        bool: @Sendable @escaping (RemoteConfigBoolKey) -> Bool = \.defaultValue,
        string: @Sendable @escaping (RemoteConfigStringKey) -> String = \.defaultValue
    ) {
        self.fetchAndActivate = fetchAndActivate ?? {}
        self.configUpdates = configUpdates
        self.bool = bool
        self.string = string
    }

}

public extension RemoteConfigClient {

    static let previewValue: RemoteConfigClient = .init()

}
