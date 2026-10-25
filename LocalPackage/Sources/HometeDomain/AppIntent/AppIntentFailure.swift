//
//  AppIntentFailure.swift
//  LocalPackage
//

/// アプリを開かずに実行するApp Intentを、実行できなかった理由
public enum AppIntentFailure: Error, Equatable, Sendable {

    /// ログインしていない（アカウントの登録を終えていない場合を含む）
    case notLoggedIn
    /// 同居人グループに所属していない
    case noCohabitant
    /// 強制アップデートが必要なバージョン
    case updateRequired
    /// メンテナンス中
    case underMaintenance

}
