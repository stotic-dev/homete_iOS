//
//  CompleteHouseworkIntent.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

/// アプリを開かずに、今日の家事を完了にする
public struct CompleteHouseworkIntent: AppIntent {

    public static let title: LocalizedStringResource = "家事を完了にする"
    public static let description = IntentDescription("アプリを開かずに、今日の家事を完了にします")
    /// 家事の名前をロック画面に出さないため、端末のロックを解除してから実行する
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$housework)を完了にする")
    }

    @Parameter(title: "家事", requestValueDialog: "どの家事を完了にしますか？")
    public var housework: HouseworkTitleEntity

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    init(housework: HouseworkTitleEntity) {
        self.housework = housework
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = housework.id
        let outcome = try await environment.perform(.completeHousework, result: \.analyticsResult) {
            try await environment.houseworkService.completeHousework(title: title, now: .now)
        }
        switch outcome {
        case let .completed(point):
            return .result(dialog: .init(.localized("おつかれさまでした。\(title)を記録しました（+\(point)pt）")))

        case .notFound:
            return .result(dialog: .init(.localized("今日の家事に\(title)はありません")))

        case .alreadyCompleted:
            return .result(dialog: .init(.localized("\(title)はもう終わっています")))

        case .pendingSync:
            return .result(dialog: .init(.localized(
                "おつかれさまでした。通信がつながりにくいため、\(title)の記録はオンラインになってから反映されます"
            )))
        }
    }

}

private extension CompleteHouseworkOutcome {

    var analyticsResult: AppIntentAnalyticsResult {
        switch self {
        case .completed:
            .success

        case .notFound:
            .notFound

        case .alreadyCompleted:
            .alreadyCompleted

        case .pendingSync:
            .pendingSync
        }
    }

}
