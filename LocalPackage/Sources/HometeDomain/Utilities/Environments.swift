//
//  Environments.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import SwiftUI

public extension EnvironmentValues {

    /// 現在の日付のDateオブジェクトを返す
    @Entry var now = Date.now

    /// 家事データの保存期間ポリシー
    /// - Note: `SubscriptionStore`の加入状態から`AppTabView`で注入する
    @Entry var houseworkStoragePolicy = HouseworkStoragePolicy.free

    /// アプリ全体で広告表示が有効かどうか
    /// - Note: `RemoteConfigStore`が起動時に確定させた値を`RootView`で注入する。
    ///         プレビューでは広告を出さない既定値のままになる
    @Entry var isAdsEnabled = RemoteConfigBoolKey.adsEnabled.defaultValue

}
