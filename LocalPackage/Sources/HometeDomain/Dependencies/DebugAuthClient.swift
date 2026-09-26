//
//  DebugAuthClient.swift
//  LocalPackage
//

/// デバッグメニューからログイン情報の失効を再現するためのクライアント
/// - Note: 呼び出すCloud FunctionはSTGプロジェクトでしか動かない。
///         リリースビルドでは`AppDependencies.liveValue`が`previewValue`（何もしない実装）を渡す
public struct DebugAuthClient: Sendable {

    /// 呼び出し元自身のリフレッシュトークンをサーバー側で失効させる
    public let revokeOwnRefreshTokens: @Sendable () async throws -> Void
    /// IDトークンを強制的に取り直す
    /// - Note: 失効済みの場合は失敗し、Firebase Authが「ログイン情報が無効」と判断して自動サインアウトする
    public let refreshIdToken: @Sendable () async throws -> Void

    public init(
        revokeOwnRefreshTokens: @Sendable @escaping () async throws -> Void = {},
        refreshIdToken: @Sendable @escaping () async throws -> Void = {}
    ) {
        self.revokeOwnRefreshTokens = revokeOwnRefreshTokens
        self.refreshIdToken = refreshIdToken
    }

}

public extension DebugAuthClient {

    static let previewValue = DebugAuthClient()

}
