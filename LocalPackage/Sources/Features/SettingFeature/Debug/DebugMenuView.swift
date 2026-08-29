//
//  DebugMenuView.swift
//  LocalPackage
//

#if DEBUG

import HometeUI
import SwiftUI

/// 実機で再現しづらいフローを直接呼び出すためのデバッグ画面
/// - Note: DEBUGビルド限定。本番ビルドには含まれない
struct DebugMenuView: View {

    @Environment(\.routeResolver) var router

    @State var isShowOnboarding = false
    @State var isShowPaywall = false

    var body: some View {
        List {
            Section("オンボーディング") {
                Button("アカウント登録からPaywallまでを表示") {
                    isShowOnboarding = true
                }
                Text("ダミーのアカウント・購読情報で動作します。実際のアカウント情報や購読状態は変更されません。")
                    .font(with: .caption)
                    .foregroundStyle(.primary2)
            }
            Section("課金") {
                Button("Paywallを表示") {
                    isShowPaywall = true
                }
            }
        }
        .navigationTitle("デバッグメニュー")
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .fullScreenCoverOnIOS(isPresented: $isShowOnboarding) {
            router.resolve(.debugOnboarding)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
    }

}

#endif
