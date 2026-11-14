//
//  Environments.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    /// アプリ全体で広告表示が有効かどうか
    /// - Note: `AdvertisementStore`が起動時に確定させた値を`RootView`で注入する。
    ///         プレビューでは広告を出さない既定値のままになる
    @Entry var isAdsEnabled = RemoteConfigBoolKey.adsEnabled.defaultValue

}
