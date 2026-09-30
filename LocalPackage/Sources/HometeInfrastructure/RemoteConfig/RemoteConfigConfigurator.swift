//
//  RemoteConfigConfigurator.swift
//

import FirebaseRemoteConfig
import HometeDomain

/// Firebase Remote Configの設定とアプリ内デフォルト値を登録する。
///
/// `FirebaseApp.configure()` の後、最初にfetchするより前に呼ぶこと。
public enum RemoteConfigConfigurator {

    /// 起動を待たせないよう、fetchは短い時間で打ち切る（SDKの既定は60秒）
    /// - Note: サーバーへのリクエスト単位のタイムアウトで、fetch全体の上限ではない。
    ///         初回はFirebase Installationsのトークン取得が先に挟まるため、さらに遅れ得る
    private static let fetchTimeout: TimeInterval = 3

    /// - Parameter minimumFetchInterval: サーバーへ問い合わせる最小間隔。この間隔内のfetchは
    ///   キャッシュを返すだけになる。Releaseは既定の12時間、Debug/Stgは切り替えを確認しやすいよう0秒を渡す
    public static func configure(minimumFetchInterval: TimeInterval) {
        let remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = minimumFetchInterval
        settings.fetchTimeout = fetchTimeout
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults(
            Dictionary(uniqueKeysWithValues: RemoteConfigBoolKey.allCases.map {
                ($0.rawValue, NSNumber(value: $0.defaultValue))
            })
        )
    }

}
