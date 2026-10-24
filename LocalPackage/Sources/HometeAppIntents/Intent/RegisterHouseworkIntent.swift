//
//  RegisterHouseworkIntent.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

/// アプリを開かずに、これからやる家事を今日の家事に登録する
///
/// 「買い物行くから登録しておいて」のように、家事の名前を言うだけで登録できるようにする。
/// いつもの家事から似ている家事を提案し、無ければ新しく登録する。
public struct RegisterHouseworkIntent: AppIntent {

    public static let title: LocalizedStringResource = "これからやる家事を登録する"
    public static let description = IntentDescription("これからやる家事の名前を伝えると、アプリを開かずに今日の家事に追加します")
    /// 家事の名前をロック画面に出さないため、端末のロックを解除してから実行する
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$title)を登録する") {
            \.$note
        }
    }

    @Parameter(title: "家事の名前", requestValueDialog: "どの家事を登録しますか？")
    public var title: String

    /// 家事のメモに入れる補足（「牛乳と卵」など）
    @Parameter(title: "メモ", inputOptions: .init(multiline: false))
    public var note: String?

    /// 似ている家事を提案するときに、選んでもらった家事
    @Parameter(title: "家事の候補")
    var suggestion: HouseworkSuggestionEntity?

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !FrequentHouseworkContext.normalize(title).isEmpty else {
            throw $title.needsValueError(.init(.localized("どの家事を登録しますか？")))
        }
        let title = title
        let note = note
        let suggestion = suggestion
        let outcome = try await environment.perform(.registerHousework, result: \.analyticsResult) {
            // ショートカットAppで候補を指定されていれば、聞き返さずにそれを登録する
            if let suggestion {
                return try await register(suggestion.target, note: note)
            }
            let plan = try await environment.houseworkService.voicePlan(title: title, note: note, now: .now)
            // 聞き返した後に断らないよう、先にメモの長さを確かめる
            if plan.isNoteTooLong {
                return Outcome.registered(.memoLimitExceeded)
            }
            // 終わった家事だけなら、もう一度やるものとして登録する
            if case let .incomplete(item) = plan.todayMatch {
                return .registered(.alreadyRegistered(title: item.title))
            }
            guard let target = try await resolveTarget(plan) else { return .cancelled }
            return try await register(target, note: note)
        }
        switch outcome {
        case let .registered(.registered(title)):
            return .result(dialog: .init(.localized("今日の家事に\(title)を追加しました")))

        case let .registered(.alreadyRegistered(title)):
            return .result(dialog: .init(.localized("\(title)は、今日の家事にもうあります")))

        case .registered(.memoLimitExceeded):
            return .result(dialog: .init(.localized("メモが長すぎるため、追加できませんでした。短くしてからもう一度お試しください")))

        case let .registered(.pendingSync(title)):
            return .result(dialog: .init(.localized(
                "通信がつながりにくいため、\(title)はオンラインになってから今日の家事に追加されます"
            )))

        case .cancelled:
            return .result(dialog: .init(.localized("追加しませんでした")))
        }
    }

}

private extension RegisterHouseworkIntent {

    /// 登録した結果か、確認で「いいえ」と答えて登録しなかったか
    enum Outcome {

        case registered(RegisterHouseworkOutcome)
        case cancelled

        var analyticsResult: AppIntentAnalyticsResult {
            switch self {
            case .registered(.registered):
                .success

            case .registered(.alreadyRegistered):
                .alreadyRegistered

            case .registered(.memoLimitExceeded):
                .memoLimitExceeded

            case .registered(.pendingSync):
                .pendingSync

            case .cancelled:
                .cancelled
            }
        }

    }

    func register(_ target: VoiceHouseworkTarget, note: String?) async throws -> Outcome {
        try await .registered(environment.houseworkService.registerHousework(target, note: note, now: .now))
    }

    /// いつもの家事から提案するか、新しく登録してよいかを確かめる
    /// - Returns: 登録する家事。確認に「いいえ」と答えたら`nil`
    func resolveTarget(_ plan: VoiceHouseworkPlan) async throws -> VoiceHouseworkTarget? {
        let newTarget = HouseworkSuggestionEntity(target: .title(plan.title))
        do {
            switch plan.suggestions.count {
            case 0:
                break

            case 1:
                let candidate = HouseworkSuggestionEntity(plan.suggestions[0])
                let isConfirmed = try await $suggestion.requestConfirmation(
                    for: candidate,
                    dialog: .init(.localized("いつもの家事の「\(plan.suggestions[0].title)」を追加しますか？"))
                )
                if isConfirmed {
                    return candidate.target
                }

            default:
                return try await $suggestion.requestDisambiguation(
                    among: plan.suggestions.map(HouseworkSuggestionEntity.init) + [newTarget],
                    dialog: .init(.localized("どの家事を追加しますか？"))
                ).target
            }
            // 聞き間違いで別の名前の家事を作らないよう、新しく登録する前に確かめる
            let isConfirmed = try await $title.requestConfirmation(
                for: plan.title,
                dialog: .init(.localized("「\(plan.title)」を新しく登録しますか？"))
            )
            return isConfirmed ? newTarget.target : nil
        } catch {
            throw AppIntentUserInteractionInterrupted(underlyingError: error)
        }
    }

}
