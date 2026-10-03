//
//  ForceUpdateStore.swift
//  LocalPackage
//

import Observation

/// 強制アップデートが必要かどうかを管理する
///
/// 最低バージョンはRemote Configの`minimum_required_version`で配信する。経緯は ADR-0034 を参照。
@MainActor
@Observable
public final class ForceUpdateStore {

    /// 強制アップデートが必要な状態。不要なら`nil`
    /// - Note: 古いバージョンを早く止められるよう、新しい値を反映するたびに判定し直す
    public private(set) var forceUpdateRequirement: ForceUpdateRequirement?

    private let remoteConfigClient: RemoteConfigClient
    /// 実行中のアプリのバージョン（`CFBundleShortVersionString`）
    private let currentAppVersion: String

    public init(
        remoteConfigClient: RemoteConfigClient = .previewValue,
        currentAppVersion: String = "",
        forceUpdateRequirement: ForceUpdateRequirement? = nil
    ) {
        self.remoteConfigClient = remoteConfigClient
        self.currentAppVersion = currentAppVersion
        self.forceUpdateRequirement = forceUpdateRequirement
    }

    /// 起動時に最新の値を取得し、強制アップデートを判定する
    /// - Note: 起動処理とは並行に走らせ、完了を待たない。取得に失敗・タイムアウトした場合は
    ///         前回反映済みの値（それも無ければアプリ内デフォルト値）で判定する
    public func setupOnLaunch() async {
        // 取得を待たずに、前回の起動までに反映済みの値で先に判定しておく
        updateForceUpdateRequirement()
        await fetchAndActivate()
        updateForceUpdateRequirement()
    }

    /// フォアグラウンド復帰時に最新の値を取得し、強制アップデートを判定し直す
    public func refresh() async {
        await fetchAndActivate()
        updateForceUpdateRequirement()
    }

    /// コンソールで公開された変更を受け取り続ける
    /// - Note: 呼び出し元のTaskがキャンセルされるまで終わらない
    public func observeConfigUpdates() async {
        for await _ in remoteConfigClient.configUpdates() {
            updateForceUpdateRequirement()
        }
    }

}

private extension ForceUpdateStore {

    func fetchAndActivate() async {
        do {
            try await remoteConfigClient.fetchAndActivate()
        } catch {
            print("[ForceUpdateStore] failed to fetch and activate: \(error)")
        }
    }

    func updateForceUpdateRequirement() {
        let minimumRequiredVersion = remoteConfigClient.string(.minimumRequiredVersion)
        if !minimumRequiredVersion.isEmpty, AppVersion(minimumRequiredVersion) == nil {
            // ブロックしない側に倒すため、設定ミスに気づける手がかりだけ残す
            print("[ForceUpdateStore] invalid minimum_required_version: \(minimumRequiredVersion)")
        }
        forceUpdateRequirement = .make(
            currentVersion: currentAppVersion,
            minimumRequiredVersion: minimumRequiredVersion,
            message: remoteConfigClient.string(.forceUpdateMessage)
        )
    }

}
