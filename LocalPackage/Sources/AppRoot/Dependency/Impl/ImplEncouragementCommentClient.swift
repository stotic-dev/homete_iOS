//
//  ImplEncouragementCommentClient.swift
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import HometeDomain

extension EncouragementCommentClient {

    /// 端末内のFoundation Modelsで生成する（ADR-0040）
    ///
    /// アプリはiOS 17から動くため、iOS 26未満では使えない扱いにして固定文言へフォールバックさせる。
    static let liveValue: EncouragementCommentClient = .init { context in
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try await FoundationModelsEncouragementGenerator.generate(context: context)
        }
        #endif
        throw EncouragementCommentError.unavailable
    }

}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
private enum FoundationModelsEncouragementGenerator {

    /// 生成を待つ上限。超えたら固定文言を出し、ダッシュボードのコメントを待たせ続けない
    static let timeout: Duration = .seconds(10)

    static func generate(context: EncouragementContext) async throws -> String {
        let model = SystemLanguageModel.default
        // 非対応端末・Apple Intelligenceがオフ・モデルの準備中・日本語に対応していない場合は生成しない
        guard model.isAvailable, model.supportsLocale(Locale(identifier: "ja_JP")) else {
            print("[EncouragementCommentClient] model is unavailable: \(model.availability)")
            throw EncouragementCommentError.unavailable
        }

        let session = LanguageModelSession(model: model, instructions: EncouragementPrompt.instructions)
        let prompt = EncouragementPrompt.prompt(context: context)
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await session.respond(to: prompt).content
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw EncouragementCommentError.timeout
            }
            defer { group.cancelAll() }
            guard let text = try await group.next() else { throw EncouragementCommentError.timeout }

            return text
        }
    }

}
#endif
