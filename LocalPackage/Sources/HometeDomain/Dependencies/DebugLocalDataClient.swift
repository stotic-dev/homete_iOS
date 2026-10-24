//
//  DebugLocalDataClient.swift
//  LocalPackage
//

/// デバッグメニューから、端末に残したデータを消すためのクライアント
/// - Note: リリースビルドでは`AppDependencies.liveValue`が`previewValue`（何もしない実装）を渡す
public struct DebugLocalDataClient: Sendable {

    /// 端末に保存した設定・記録（UserDefaults）を、通知拡張と共有している分も含めてすべて消す
    public let removeAll: @Sendable () async -> Void

    public init(removeAll: @Sendable @escaping () async -> Void = {}) {
        self.removeAll = removeAll
    }

}

public extension DebugLocalDataClient {

    static let previewValue = DebugLocalDataClient()

}
