//
//  RecordHouseworkIntent.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

/// アプリを開かずに、やった家事を記録する
///
/// 「洗濯干したから記録しておいて」のように、家事の名前を言うだけで記録できるようにする。
/// 今日の家事に同じ名前があればそれを完了にし、無ければいつもの家事から似ている家事を提案し、
/// それも無ければ新しく作って完了にする。
public struct RecordHouseworkIntent: AppIntent {

    public static let title: LocalizedStringResource = "やった家事を記録する"
    public static let description = IntentDescription("やった家事の名前を伝えると、アプリを開かずに記録します")
    /// 家事の名前をロック画面に出さないため、端末のロックを解除してから実行する
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$title)を記録する")
    }

    @Parameter(title: "家事の名前", requestValueDialog: "どの家事をしましたか？")
    public var title: String

    /// 似ている家事を提案するときに、選んでもらった家事
    @Parameter(title: "家事の候補")
    var suggestion: HouseworkSuggestionEntity?

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !FrequentHouseworkContext.normalize(title).isEmpty else {
            throw $title.needsValueError(.init(.localized("どの家事をしましたか？")))
        }
        let title = title
        let suggestion = suggestion
        let outcome = try await environment.perform(.recordHousework, result: \.analyticsResult) {
            // ショートカットAppで候補を指定されていれば、聞き返さずにそれを記録する
            if let suggestion {
                return try await record(suggestion.target)
            }
            let plan = try await environment.houseworkService.voicePlan(title: title, note: nil, now: .now)
            switch plan.todayMatch {
            case let .incomplete(item):
                return try await record(.today(title: item.title))

            case let .completed(completedTitle):
                return .recorded(.alreadyCompleted(title: completedTitle))

            case nil:
                guard let target = try await resolveTarget(plan) else { return .cancelled }
                return try await record(target)
            }
        }
        switch outcome {
        case let .recorded(.completed(title, point)):
            return .result(dialog: .init(.localized("おつかれさまでした。\(title)を記録しました（+\(point)pt）")))

        case let .recorded(.alreadyCompleted(title)):
            return .result(dialog: .init(.localized("\(title)はもう終わっています")))

        case let .recorded(.pendingSync(title)):
            return .result(dialog: .init(.localized(
                "おつかれさまでした。通信がつながりにくいため、\(title)の記録はオンラインになってから反映されます"
            )))

        case .cancelled:
            return .result(dialog: .init(.localized("記録しませんでした")))
        }
    }

}

private extension RecordHouseworkIntent {

    /// 記録した結果か、確認で「いいえ」と答えて記録しなかったか
    enum Outcome {

        case recorded(RecordHouseworkOutcome)
        case cancelled

        var analyticsResult: AppIntentAnalyticsResult {
            switch self {
            case .recorded(.completed):
                .success

            case .recorded(.alreadyCompleted):
                .alreadyCompleted

            case .recorded(.pendingSync):
                .pendingSync

            case .cancelled:
                .cancelled
            }
        }

    }

    func record(_ target: VoiceHouseworkTarget) async throws -> Outcome {
        try await .recorded(environment.houseworkService.recordHousework(target, now: .now))
    }

    /// 今日の家事に同じ名前が無いとき、名前が似ている今日の家事・いつもの家事を提案するか、新しく作ってよいかを確かめる
    /// - Returns: 記録する家事。確認に「いいえ」と答えたら`nil`
    func resolveTarget(_ plan: VoiceHouseworkPlan) async throws -> VoiceHouseworkTarget? {
        let candidates = Self.candidates(plan)
        let newTarget = HouseworkSuggestionEntity(target: .title(plan.title))
        do {
            switch candidates.count {
            case 0:
                break

            case 1:
                let isConfirmed = try await $suggestion.requestConfirmation(
                    for: candidates[0],
                    dialog: confirmationDialog(candidates[0].target)
                )
                if isConfirmed {
                    return candidates[0].target
                }

            default:
                return try await $suggestion.requestDisambiguation(
                    among: candidates + [newTarget],
                    dialog: .init(.localized("どの家事を記録しますか？"))
                ).target
            }
            // 聞き間違いで別の名前の家事を作らないよう、新しく作る前に確かめる
            let isConfirmed = try await $title.requestConfirmation(
                for: plan.title,
                dialog: .init(.localized("「\(plan.title)」を新しく登録して、記録しますか？"))
            )
            return isConfirmed ? newTarget.target : nil
        } catch {
            throw AppIntentUserInteractionInterrupted(underlyingError: error)
        }
    }

    /// 今日の未完了の家事を先に、同じ名前のいつもの家事を除いて並べる
    static func candidates(_ plan: VoiceHouseworkPlan, limit: Int = 5) -> [HouseworkSuggestionEntity] {
        let todayKeys = Set(plan.todaySuggestions.map(HouseworkTitleSimilarity.normalized))
        let today = plan.todaySuggestions.map { HouseworkSuggestionEntity(target: .today(title: $0)) }
        let frequent = plan.suggestions
            .filter { !todayKeys.contains(HouseworkTitleSimilarity.normalized($0.title)) }
            .map(HouseworkSuggestionEntity.init)
        return Array((today + frequent).prefix(limit))
    }

    func confirmationDialog(_ target: VoiceHouseworkTarget) -> IntentDialog {
        switch target {
        case let .today(title):
            .init(.localized("今日の家事の「\(title)」を完了にしますか？"))

        case let .frequent(_, title):
            .init(.localized("いつもの家事の「\(title)」を完了にしますか？"))

        case let .title(title):
            .init(.localized("「\(title)」を新しく登録して、記録しますか？"))
        }
    }

}
