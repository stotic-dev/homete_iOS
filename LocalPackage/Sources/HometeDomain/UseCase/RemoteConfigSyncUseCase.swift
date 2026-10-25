//
//  RemoteConfigSyncUseCase.swift
//  LocalPackage
//

/// Remote Configの最新の値を取得し、値を使う領域のStoreへ反映させる
///
/// fetch・activateは全キーまとめて1回だけ行い、値をいつ画面へ反映するかは各Storeに任せる。
/// 経緯は ADR-0033 / ADR-0035 / ADR-0055 を参照。
@MainActor
public struct RemoteConfigSyncUseCase {

    private let remoteConfigClient: RemoteConfigClient
    private let advertisementStore: AdvertisementStore
    private let forceUpdateStore: ForceUpdateStore
    private let maintenanceStore: MaintenanceStore

    public init(
        remoteConfigClient: RemoteConfigClient = .previewValue,
        advertisementStore: AdvertisementStore,
        forceUpdateStore: ForceUpdateStore,
        maintenanceStore: MaintenanceStore
    ) {
        self.remoteConfigClient = remoteConfigClient
        self.advertisementStore = advertisementStore
        self.forceUpdateStore = forceUpdateStore
        self.maintenanceStore = maintenanceStore
    }

    /// 起動時に最新の値を取得し、各Storeへ反映させる
    /// - Note: 起動処理とは並行に走らせ、完了を待たない。取得に失敗・タイムアウトした場合は
    ///         前回反映済みの値（それも無ければアプリ内デフォルト値）で反映させる
    public func setupOnLaunch() async {
        // 取得を待たずに、前回の起動までに反映済みの値で先に判定しておく
        updateAppAvailability()
        await fetchAndActivate()
        advertisementStore.confirmAdsEnabled()
        updateAppAvailability()
    }

    /// フォアグラウンド復帰時に最新の値を取得し、起動中も反映するキーだけ反映させる
    /// - Note: 起動中の広告表示の有無は変えない。取得した値は次回起動時に使われる
    public func refresh() async {
        await fetchAndActivate()
        updateAppAvailability()
    }

    /// コンソールで公開された変更を受け取り続け、起動中も反映するキーだけ反映させる
    /// - Note: 呼び出し元のTaskがキャンセルされるまで終わらない。リスナーを1つにするため、Storeごとには購読しない
    public func observeConfigUpdates() async {
        for await _ in remoteConfigClient.configUpdates() {
            updateAppAvailability()
        }
    }

}

private extension RemoteConfigSyncUseCase {

    /// 起動中も反映するキー（利用を止めるかどうか）を反映させる
    func updateAppAvailability() {
        forceUpdateStore.updateRequirement()
        maintenanceStore.updateState()
    }

    func fetchAndActivate() async {
        do {
            try await remoteConfigClient.fetchAndActivate()
        } catch {
            print("[RemoteConfigSyncUseCase] failed to fetch and activate: \(error)")
        }
    }

}
