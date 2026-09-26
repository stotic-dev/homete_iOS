//
//  DebugMenuView.swift
//  LocalPackage
//

#if DEBUG

import HometeDomain
import HometeUI
import SwiftUI

/// 実機で再現しづらいフローを直接呼び出すためのデバッグ画面
/// - Note: DEBUGビルド限定。本番ビルドには含まれない
struct DebugMenuView: View {

    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.dailyCompletionReminderUseCase) var dailyCompletionReminderUseCase
    @Environment(\.appDependencies.debugAuthClient) var debugAuthClient

    @State var isShowOnboarding = false
    @State var isShowPaywall = false
    @State var isShowCohabitantRegistration = false
    @State var isDailyCompletionReminderLimitDisabled = false
    @State var isShowRevokeResult = false
    @State var revokeResultMessage = ""

    var body: some View {
        List {
            Section("オンボーディング") {
                Button("アカウント登録からPaywallまでを表示") {
                    isShowOnboarding = true
                }
                Text("ダミーのアカウント・購読情報で動作します。実際のアカウント情報や購読状態は変更されません。")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            Section("同居人の登録") {
                Button("P2P登録を試す") {
                    isShowCohabitantRegistration = true
                }
                Text("複数の端末でこの画面を開くと、実際のP2P通信で登録を最後まで試せます。グループの作成と同居人IDの保存はモックのため、今のグループや登録状態は変わりません。")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            Section("ふりかえり通知") {
                Toggle("1日1回の制限を外す", isOn: dailyCompletionReminderLimitBinding)
                Text("家事が完了するたびに、設定した時刻の通知を別々に予約します。設定時刻を過ぎていると予約されないため、動作確認では通知設定の時刻を数分後にしてください。")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            Section("課金") {
                Button("Paywallを表示") {
                    isShowPaywall = true
                }
            }
            Section("ログイン情報の失効") {
                Button("失効させる（アプリはこのまま）") {
                    Task { await revokeRefreshTokens() }
                }
                Button("失効させて、すぐにトークンを取り直す") {
                    Task { await revokeRefreshTokensAndRefresh() }
                }
                Text("""
                サーバー側で自分のログイン情報を失効させます。STG環境限定で、本番では動きません。

                「アプリはこのまま」を選んだ後にアプリを終了して起動し直すと、起動直後に自動サインアウトされる状況を再現できます。\
                「すぐにトークンを取り直す」を選ぶと、その場でログイン画面に戻ります。

                どちらの場合も、もう一度ログインすればそのまま使えるようになります。
                """)
                .font(with: .caption)
                .foregroundStyle(.onSurfaceVariant)
            }
        }
        .alert("ログイン情報の失効", isPresented: $isShowRevokeResult) {
            Button("OK") {}
        } message: {
            Text(revokeResultMessage)
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
        .fullScreenCoverOnIOS(isPresented: $isShowCohabitantRegistration) {
            router.resolve(.debugCohabitantRegistration)
        }
        .task {
            isDailyCompletionReminderLimitDisabled = await dailyCompletionReminderUseCase.loadIsDailyLimitDisabled()
        }
    }

}

private extension DebugMenuView {

    var dailyCompletionReminderLimitBinding: Binding<Bool> {
        .init {
            isDailyCompletionReminderLimitDisabled
        } set: { isDisabled in
            isDailyCompletionReminderLimitDisabled = isDisabled
            Task {
                await dailyCompletionReminderUseCase.updateIsDailyLimitDisabled(isDisabled)
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension DebugMenuView {

    /// サーバー側でログイン情報を失効させる
    /// - Note: 失効させただけではクライアントは気付かない。次にトークンを取り直すタイミング
    ///         （多くはアプリの起動時）にFirebase Authが自動サインアウトする
    func revokeRefreshTokens() async {
        do {
            try await debugAuthClient.revokeOwnRefreshTokens()
            showResult("失効させました。アプリを終了して起動し直すと、起動直後の自動サインアウトを再現できます。")
        } catch {
            showResult("失効に失敗しました: \(error)")
        }
    }

    /// ログイン情報を失効させた直後にトークンを取り直し、その場で自動サインアウトさせる
    func revokeRefreshTokensAndRefresh() async {
        do {
            try await debugAuthClient.revokeOwnRefreshTokens()
        } catch {
            showResult("失効に失敗しました: \(error)")
            return
        }

        do {
            try await debugAuthClient.refreshIdToken()
            // 失効済みなら更新は失敗するはずなので、成功した場合は失効が効いていない
            showResult("トークンの取り直しが成功してしまいました。失効が反映されていない可能性があります。")
        } catch {
            showResult("失効させ、トークンの取り直しに失敗しました。ログイン画面に戻ります。")
        }
    }

    func showResult(_ message: String) {
        revokeResultMessage = message
        isShowRevokeResult = true
    }

}

#endif
