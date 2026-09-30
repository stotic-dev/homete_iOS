//
//  RemoteConfigStore.swift
//  LocalPackage
//

import Observation

/// Remote Configの値を画面へ届ける
///
/// fetch・activateは全キーまとめて行い、値をいつ画面へ反映するかはキーごとにこのStoreで決める。
/// 経緯は ADR-0031 を参照。
@MainActor
@Observable
public final class RemoteConfigStore {

    /// 広告表示を有効にするかどうか
    /// - Note: 表示中に広告が出たり消えたりするとレイアウトが崩れるため、起動時に1回だけ確定させ、
    ///         以降はフォアグラウンド復帰で新しい値を取得しても起動中は変えない
    public private(set) var isAdsEnabled: Bool

    private let remoteConfigClient: RemoteConfigClient

    public init(
        remoteConfigClient: RemoteConfigClient = .previewValue,
        isAdsEnabled: Bool = RemoteConfigBoolKey.adsEnabled.defaultValue
    ) {
        self.remoteConfigClient = remoteConfigClient
        self.isAdsEnabled = isAdsEnabled
    }

    /// 起動時に最新の値を取得し、起動中に固定する値を確定させる
    /// - Note: 起動処理とは並行に走らせ、完了を待たない。取得に失敗・タイムアウトした場合は
    ///         前回反映済みの値（それも無ければアプリ内デフォルト値）で確定させる
    public func setupOnLaunch() async {
        await fetchAndActivate()
        isAdsEnabled = remoteConfigClient.bool(.adsEnabled)
    }

    /// フォアグラウンド復帰時に最新の値を取得する
    /// - Note: 起動中に固定する値（`isAdsEnabled`）は更新しない
    public func refresh() async {
        await fetchAndActivate()
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

}
