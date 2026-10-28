//
//  MaintenanceStateClient.swift
//  LocalPackage
//

/// メンテナンス中かどうかを、アプリ本体とNotification Service Extensionで共有する
///
/// 拡張はRemote Configを読めないため、アプリが最後に反映した判定を端末に残して拡張から読む。
public struct MaintenanceStateClient: Sendable {

    /// アプリが最後に反映した判定を読む。一度も保存していなければ`false`
    public let load: @Sendable () -> Bool
    /// 反映した判定を保存する
    public let save: @Sendable (Bool) -> Void

    public init(
        load: @Sendable @escaping () -> Bool = { false },
        save: @Sendable @escaping (Bool) -> Void = { _ in }
    ) {
        self.load = load
        self.save = save
    }

}

public extension MaintenanceStateClient {

    static let previewValue: MaintenanceStateClient = .init()

}
