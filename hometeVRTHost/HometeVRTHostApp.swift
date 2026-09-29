//
//  HometeVRTHostApp.swift
//  hometeVRTHost
//

import SwiftUI

/// VRT（スナップショットテスト）専用のホストアプリ。
///
/// 描画対象のViewはhometeSnapshotTests側がLocalPackageの各モジュールを直接リンクして持つ。
/// このターゲットはkey windowを用意するためだけに存在し、LocalPackageには一切依存しない。
///
/// hometeアプリをホストにすると AppRoot → HometeInfrastructure 経由で
/// Firebase / AdMob / RevenueCat のビルドが丸ごと必要になり、VRTの実行時間を押し上げる。
@main
struct HometeVRTHostApp: App {

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }

}
