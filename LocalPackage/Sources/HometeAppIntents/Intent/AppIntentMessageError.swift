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

        case .underMaintenance:
            localizedStringResource = .localized("メンテナンス中のため、いまは使えません。しばらくお待ちください")
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
        } catch let interruption as AppIntentUserInteractionInterrupted {
            // 聞き返した選択肢をユーザーが選ばずに閉じたときは、実行の失敗として数えない
            throw interruption.underlyingError
        } catch {
            analyticsClient.log(.appIntent(intent, result: .failure))
            throw error
        }
    }

    /// Entityの候補を出す処理（Query）を実行し、実行できなかった理由をユーザーに伝える文言に変えて投げる
    ///
    /// 候補はIntentを実行する前にSiriやショートカットAppから何度も呼ばれるため、`app_intent`イベントは送らない。
    nonisolated(nonsending) func resolveEntities<Value>(_ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch let failure as AppIntentFailure {
            throw AppIntentMessageError(failure)
        }
    }

}

/// Siriの聞き返し（選択肢から選んでもらうなど）が、ユーザーが選ばずに閉じるなどで終わった
///
/// `AppIntentEnvironment.perform`は`app_intent`イベントを送らず、元のエラーを投げ直してOSに任せる。
struct AppIntentUserInteractionInterrupted: Error {

    let underlyingError: any Error

}
