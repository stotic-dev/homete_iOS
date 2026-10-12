//
//  AppIntentEnvironment.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

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
    /// - Parameter pendingRouteStore: アプリを開くIntentが、開く画面を退避する先。通知のタップと同じものを渡す
    @MainActor
    public static func configure(
        dependencies: AppDependencies,
        pendingRouteStore: PendingRouteStore,
        currentAppVersion: String
    ) {
        let environment = AppIntentEnvironment(
            dependencies: dependencies,
            currentAppVersion: currentAppVersion,
            calendar: .autoupdatingCurrent
        )
        AppDependencyManager.shared.add(dependency: environment)
        AppDependencyManager.shared.add(dependency: pendingRouteStore)
    }

}
