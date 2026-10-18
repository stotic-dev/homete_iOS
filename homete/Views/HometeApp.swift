//
//  HometeApp.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import AppIntents
import AppRoot
import HometeAppIntents
import HometeDomain
import HometeInfrastructure
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {

    let isXcodePreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    let isUnitTestMode = ProcessInfo.processInfo.arguments.contains("isUnitTestMode")
    /// タップされた通知やApp Intentから開く画面
    /// - Note: アプリが終了している状態で通知をタップすると、画面を組み立てる前に通知のタップが届くため、
    ///         画面側ではなくここで受け取って保持する
    let pendingRouteStore = PendingRouteStore()

    func application(
        _: UIApplication,
        // swiftlint:disable:next discouraged_optional_collection
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        setupFirebase()

        // Initialize RevenueCat
        setupRevenueCat()

        setupAppIntents()

        UNUserNotificationCenter.current().delegate = self
        MessagingConfigurator.configure()

        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MessagingConfigurator.setAPNSToken(deviceToken)
    }

}

// MARK: - setup

private extension AppDelegate {

    func setupFirebase() {
        // App Checkのプロバイダ登録はFirebaseApp.configure()より前に行う必要がある。
        AppCheckConfigurator.configure(usesDebugProvider: usesAppCheckDebugProvider)

        #if DEBUG
        if !isXcodePreview, !isUnitTestMode {
            guard let devPlistFilePath = (
                Bundle.main.url(
                    forResource: "GoogleService-Info-dev",
                    withExtension: "plist"
                )?
                    .path()
            ) else { return }
            FirebaseConfigurator.configure(optionsFilePath: devPlistFilePath)
        }
        #else
        FirebaseConfigurator.configure()
        #endif

        // プレビュー・ユニットテストではFirebaseを初期化しないため、Remote Configも設定しない
        guard FirebaseConfigurator.isConfigured else { return }
        RemoteConfigConfigurator.configure(minimumFetchInterval: remoteConfigMinimumFetchInterval)
    }

    /// Xcodeから実行するローカルビルドかどうか。
    ///
    /// Stg構成はTestFlight配布でありながらDEBUGを定義している（開発用のFirebaseプロジェクトを
    /// 参照するため）ので、DEBUGだけではローカルビルドと区別できない。Stg構成にだけ定義した
    /// STGフラグで除外する。
    var usesAppCheckDebugProvider: Bool {
        #if DEBUG && !STG
        true
        #else
        false
        #endif
    }

    /// Remote Configでサーバーへ問い合わせる最小間隔。
    ///
    /// Debug/Stgはコンソールでの切り替えをすぐ確認できるよう0秒にする。Stg構成もDEBUGを定義しているので、
    /// App Checkと違ってSTGでの除外は不要。Releaseは既定の12時間。
    var remoteConfigMinimumFetchInterval: TimeInterval {
        #if DEBUG
        0
        #else
        12 * 60 * 60
        #endif
    }

    func setupRevenueCat() {
        guard !isXcodePreview, !isUnitTestMode else { return }
        RevenueCatClient.shared.initialize()
    }

    /// App Intentが使う依存を登録する
    /// - Note: アプリを開かないIntentもアプリのプロセスを起動して実行されるため、Firebaseの初期化と同じく起動時に行う。
    ///         家事の名前の読み直しは、家事を読み込んだとき（`HouseworkListStore`）に頼む
    func setupAppIntents() {
        // プレビュー・ユニットテストではFirebaseを初期化しないため、Firebaseを使うIntentも登録しない
        guard FirebaseConfigurator.isConfigured else { return }
        HometeAppIntentsConfigurator.configure(
            dependencies: .liveValue,
            pendingRouteStore: pendingRouteStore,
            currentAppVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            updateAppShortcutParameters: { HometeAppShortcuts.updateAppShortcutParameters() }
        )
    }

}

// MARK: - Delegate Conformances

extension AppDelegate: @MainActor UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // アプリ起動中でも同居人の家事完了などに気づけるよう、バナーと通知センターにも表示する
        [.banner, .list, .sound]
    }

    /// 通知のタップを受け取り、開く画面を保持する
    /// - Note: メインアクターで受け取る。`nonisolated`にすると、処理を終えたことをOSへ返す完了ハンドラが
    ///         メインスレッド以外から呼ばれ、UIKitが`Call must be made on main thread`で落ちる
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let route = PendingRoute(userInfo: response.notification.request.content.userInfo) else { return }

        pendingRouteStore.store(route)
    }

}

@main
struct HometeApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State var fcmToken: String?

    var body: some Scene {
        WindowGroup {
            if delegate.isUnitTestMode {
                EmptyView()
            } else {
                RootView.make(
                    dependencies: .liveValue,
                    pendingRouteStore: delegate.pendingRouteStore
                )
            }
        }
    }

}
