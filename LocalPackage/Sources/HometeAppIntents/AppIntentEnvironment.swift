//
//  AppIntentEnvironment.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain
import os

/// App Intentが使う依存
///
/// アプリの起動時に`HometeAppIntentsConfigurator.configure`で登録し、Intentは`@Dependency`で受け取る。
/// Firebaseの実装はアプリが`AppDependencies.liveValue`として渡すので、このパッケージは`HometeInfrastructure`に依存しない。
struct AppIntentEnvironment {

    let dependencies: AppDependencies
    let currentAppVersion: String
    let calendar: Calendar

    var analyticsClient: AnalyticsClient {
        dependencies.analyticsClient
    }

    var houseworkService: HouseworkIntentService {
        .init(
            sessionUseCase: .init(
                accountAuthClient: dependencies.accountAuthClient,
                accountInfoClient: dependencies.accountInfoClient,
                cohabitantClient: dependencies.cohabitantClient,
                houseworkClient: dependencies.houseworkClient,
                houseworkTemplateClient: dependencies.houseworkTemplateClient,
                remoteConfigClient: dependencies.remoteConfigClient,
                currentAppVersion: currentAppVersion
            ),
            commandUseCase: .init(
                houseworkClient: dependencies.houseworkClient,
                cohabitantPushNotificationClient: dependencies.cohabitantPushNotificationClient,
                analyticsClient: dependencies.analyticsClient,
                dailyCompletionReminderUseCase: dependencies.dailyCompletionReminderUseCase,
                calendar: calendar
            ),
            dailyCompletionReminderUseCase: dependencies.dailyCompletionReminderUseCase,
            calendar: calendar
        )
    }

}

/// App Intentが使う依存を登録する
public enum HometeAppIntentsConfigurator {

    /// アプリの起動時に1回だけ呼ぶ
    ///
    /// アプリを開かないIntentでもアプリのプロセスが起動して実行されるため、Intentより先に必ず呼ばれる場所（`AppDelegate`）で呼ぶ。
    /// - Parameters:
    ///   - pendingRouteStore: アプリを開くIntentが、開く画面を退避する先。通知のタップと同じものを渡す
    ///   - updateAppShortcutParameters: アプリ本体の`AppShortcutsProvider`の`updateAppShortcutParameters()`。
    ///     `AppShortcutsProvider`はアプリ本体にしか置けず、このパッケージから型を参照できないため受け取る
    @MainActor
    public static func configure(
        dependencies: AppDependencies,
        pendingRouteStore: PendingRouteStore,
        currentAppVersion: String,
        updateAppShortcutParameters: @escaping @Sendable () -> Void
    ) {
        appShortcutParametersUpdater.withLock { $0 = updateAppShortcutParameters }
        let environment = AppIntentEnvironment(
            dependencies: dependencies,
            currentAppVersion: currentAppVersion,
            calendar: .autoupdatingCurrent
        )
        AppDependencyManager.shared.add(dependency: environment)
        AppDependencyManager.shared.add(dependency: pendingRouteStore)
    }

}

extension HometeAppIntentsConfigurator {

    private static let appShortcutParametersUpdater = OSAllocatedUnfairLock<(@Sendable () -> Void)?>(initialState: nil)

    /// Siriで家事の名前を言えるよう、OSに今日の家事の名前を読み直してもらう。`configure`の前に呼ばれたら何もしない
    static func updateAppShortcutParameters() {
        appShortcutParametersUpdater.withLock { $0 }?()
    }

}
