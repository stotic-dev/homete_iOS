//
//  AdvertisementStore.swift
//  LocalPackage
//

import Observation

/// アプリ全体で広告を表示するかどうかを管理する
///
/// 広告表示の有無はRemote Configの`ads_enabled`で配信する。経緯は ADR-0033 を参照。
@MainActor
@Observable
public final class AdvertisementStore {

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

    /// 起動時の取得を終えた時点の値で、起動中の広告表示の有無を確定させる
    /// - Note: 起動時の取得が終わった後（成功・失敗を問わない）に1回だけ呼ぶ。
    ///         取得に失敗・タイムアウトした場合は前回反映済みの値（それも無ければアプリ内デフォルト値）で確定する
    public func confirmAdsEnabled() {
        isAdsEnabled = remoteConfigClient.bool(.adsEnabled)
    }

}
