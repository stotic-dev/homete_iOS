//
//  RemoteConfigClient.swift
//  LocalPackage
//

public struct RemoteConfigClient: Sendable {

    /// サーバーから最新の値を取得し、アプリから読める値に反映する
    public let fetchAndActivate: @Sendable () async throws -> Void
    /// 反映済みの値を読む。一度も反映できていなければアプリ内デフォルト値を返す
    public let bool: @Sendable (RemoteConfigBoolKey) -> Bool

    /// - Note: asyncクロージャをデフォルト引数に書くと、Xcode 26系でビルドしたテストを並列実行したときに
    ///         asyncフレームが壊れてクラッシュするため、`nil`を受けてinit本体で既定の実装を詰める
    public init(
        fetchAndActivate: (@Sendable () async throws -> Void)? = nil,
        bool: @Sendable @escaping (RemoteConfigBoolKey) -> Bool = \.defaultValue
    ) {
        self.fetchAndActivate = fetchAndActivate ?? {}
        self.bool = bool
    }

}

public extension RemoteConfigClient {

    static let previewValue: RemoteConfigClient = .init()

}
