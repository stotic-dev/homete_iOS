//
//  AppIntentMessageError.swift
//  LocalPackage
//

import AppIntents
import HometeDomain

/// Intentを実行できなかったときに、Siriやショートカットに出す文言
struct AppIntentMessageError: Error, CustomLocalizedStringResourceConvertible {

    let localizedStringResource: LocalizedStringResource

    init(_ failure: AppIntentFailure) {
        switch failure {
        case .notLoggedIn:
            localizedStringResource = .localized("アプリを開いて、ログインしてから使えます")

        case .noCohabitant:
            localizedStringResource = .localized("パートナーを招待すると使えます")

        case .updateRequired:
            localizedStringResource = .localized("アプリをアップデートしてから使えます")
        }
    }

}

extension AppIntentEnvironment {

    /// Intentの処理を実行し、結果を`app_intent`イベントで送る
    ///
    /// 実行できなかった理由が`AppIntentFailure`なら、ユーザーに伝える文言に変えて投げる。
    /// - Parameter result: 処理の戻り値から、送る結果を決める
    /// - Note: 呼び出し元のアクターで実行し、画面を組み立てる`@MainActor`の`perform`からも処理を渡せるようにする
    nonisolated(nonsending) func perform<Value>(
        _ intent: AppIntentAnalyticsIntent,
        result: (Value) -> AppIntentAnalyticsResult = { _ in .success },
        operation: () async throws -> Value
    ) async throws -> Value {
        do {
            let value = try await operation()
            analyticsClient.log(.appIntent(intent, result: result(value)))
            return value
        } catch let failure as AppIntentFailure {
            analyticsClient.log(.appIntent(intent, result: .init(failure)))
            throw AppIntentMessageError(failure)
        } catch {
            analyticsClient.log(.appIntent(intent, result: .failure))
            throw error
        }
    }

}
