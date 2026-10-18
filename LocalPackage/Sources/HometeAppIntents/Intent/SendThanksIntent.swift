//
//  SendThanksIntent.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

/// アプリを開かずに、同居人が終えた家事にありがとうを伝える
public struct SendThanksIntent: AppIntent {

    public static let title: LocalizedStringResource = "ありがとうを伝える"
    public static let description = IntentDescription("アプリを開かずに、パートナーが終えた家事にありがとうを伝えます")
    /// 家事や同居人の名前をロック画面に出さないため、端末のロックを解除してから実行する
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$target)にありがとうを伝える") {
            \.$comment
        }
    }

    /// 伝える家事。指定しなければ、ありがとうを伝えられる家事から選ぶ
    @Parameter(title: "家事")
    var target: ThanksTargetEntity?

    /// 添えるコメント。入れたときだけ相手に通知する
    @Parameter(title: "ひとこと", inputOptions: .init(multiline: false))
    var comment: String?

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let comment = comment
        let outcome = try await environment.perform(.sendThanks, result: \.analyticsResult) {
            guard let target = try await resolveTarget() else { return SendThanksOutcome.noCandidate }
            return try await environment.houseworkService.sendThanks(
                houseworkId: target.id,
                comment: comment,
                now: .now
            )
        }
        switch outcome {
        case let .sent(houseworkTitle):
            return .result(dialog: .init(.localized("\(houseworkTitle)に、ありがとうを伝えました")))

        case .notFound:
            return .result(dialog: .init(.localized("この家事には、ありがとうを伝えられません")))

        case .noCandidate:
            return .result(dialog: .init(.localized("今は、ありがとうを伝えられる家事はありません")))

        case let .pendingSync(houseworkTitle):
            return .result(dialog: .init(.localized(
                "通信がつながりにくいため、\(houseworkTitle)へのありがとうはオンラインになってから届きます"
            )))
        }
    }

}

private extension SendThanksIntent {

    /// 伝える家事を決める
    ///
    /// 指定されていなければ、候補が1件ならそれに、複数ならSiriに聞き返してもらう。
    /// - Returns: 伝えられる家事が無ければ`nil`
    func resolveTarget() async throws -> ThanksTargetEntity? {
        if let target {
            return target
        }
        let candidates = try await environment.houseworkService
            .thanksCandidates(now: .now)
            .map(ThanksTargetEntity.init)
        switch candidates.count {
        case 0:
            return nil

        case 1:
            return candidates.first

        default:
            do {
                return try await $target.requestDisambiguation(
                    among: candidates,
                    dialog: .init(.localized("どの家事にありがとうを伝えますか？"))
                )
            } catch {
                throw AppIntentUserInteractionInterrupted(underlyingError: error)
            }
        }
    }

}

private extension SendThanksOutcome {

    var analyticsResult: AppIntentAnalyticsResult {
        switch self {
        case .sent:
            .success

        case .notFound, .noCandidate:
            .notFound

        case .pendingSync:
            .pendingSync
        }
    }

}
