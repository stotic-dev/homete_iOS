//
//  RemoteConfigStore.swift
//  LocalPackage
//

import Observation

/// Remote Configの値を画面へ届ける
///
/// fetch・activateは全キーまとめて行い、値をいつ画面へ反映するかはキーごとにこのStoreで決める。
/// 経緯は ADR-0031 / ADR-0032 を参照。
@MainActor
@Observable
public final class RemoteConfigStore {

    /// 広告表示を有効にするかどうか
    /// - Note: 表示中に広告が出たり消えたりするとレイアウトが崩れるため、起動時に1回だけ確定させ、
    ///         以降はフォアグラウンド復帰で新しい値を取得しても起動中は変えない
    public private(set) var isAdsEnabled: Bool
    /// 強制アップデートが必要な状態。不要なら`nil`
    /// - Note: 古いバージョンを早く止められるよう、新しい値を反映するたびに判定し直す
    public private(set) var forceUpdateRequirement: ForceUpdateRequirement?

    private let remoteConfigClient: RemoteConfigClient
    /// 実行中のアプリのバージョン（`CFBundleShortVersionString`）
    private let currentAppVersion: String

    public init(
        remoteConfigClient: RemoteConfigClient = .previewValue,
        currentAppVersion: String = "",
        isAdsEnabled: Bool = RemoteConfigBoolKey.adsEnabled.defaultValue,
        forceUpdateRequirement: ForceUpdateRequirement? = nil
    ) {
        self.remoteConfigClient = remoteConfigClient
        self.currentAppVersion = currentAppVersion
        self.isAdsEnabled = isAdsEnabled
        self.forceUpdateRequirement = forceUpdateRequirement
    }

    /// 起動時に最新の値を取得し、起動中に固定する値を確定させる
    /// - Note: 起動処理とは並行に走らせ、完了を待たない。取得に失敗・タイムアウトした場合は
    ///         前回反映済みの値（それも無ければアプリ内デフォルト値）で確定させる
    public func setupOnLaunch() async {
        // 取得を待たずに、前回の起動までに反映済みの値で先に判定しておく
        updateForceUpdateRequirement()
        await fetchAndActivate()
        isAdsEnabled = remoteConfigClient.bool(.adsEnabled)
        updateForceUpdateRequirement()
    }

    /// フォアグラウンド復帰時に最新の値を取得する
    /// - Note: 起動中に固定する値（`isAdsEnabled`）は更新しない
    public func refresh() async {
        await fetchAndActivate()
        updateForceUpdateRequirement()
    }

    /// コンソールで公開された変更を受け取り続ける
    /// - Note: 起動中に固定する値（`isAdsEnabled`）は更新しない。呼び出し元のTaskがキャンセルされるまで終わらない
    public func observeConfigUpdates() async {
        for await _ in remoteConfigClient.configUpdates() {
            updateForceUpdateRequirement()
        }
    }

}

private extension RemoteConfigStore {

    func fetchAndActivate() async {
        do {
            try await remoteConfigClient.fetchAndActivate()
        } catch {
            print("[RemoteConfigStore] failed to fetch and activate: \(error)")
        }
    }

    func updateForceUpdateRequirement() {
        let minimumRequiredVersion = remoteConfigClient.string(.minimumRequiredVersion)
        if !minimumRequiredVersion.isEmpty, AppVersion(minimumRequiredVersion) == nil {
            // ブロックしない側に倒すため、設定ミスに気づける手がかりだけ残す
            print("[RemoteConfigStore] invalid minimum_required_version: \(minimumRequiredVersion)")
        }
        forceUpdateRequirement = .make(
            currentVersion: currentAppVersion,
            minimumRequiredVersion: minimumRequiredVersion,
            message: remoteConfigClient.string(.forceUpdateMessage)
        )
    }

}
