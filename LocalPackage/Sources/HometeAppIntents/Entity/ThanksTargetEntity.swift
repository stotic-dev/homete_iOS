//
//  ThanksTargetEntity.swift
//  LocalPackage
//

import AppIntents
import Foundation

/// ありがとうを伝える家事
///
/// 送る家事を1件に決めるため、家事のIDで表す。翌日には指す家事が候補から外れるので、ドネーションでは引数に入れない。
struct ThanksTargetEntity: AppEntity {

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "ありがとうを伝える家事"
    static let defaultQuery = ThanksTargetQuery()

    /// 家事のID
    let id: String
    /// 家事の名前
    let title: String
    /// 家事を担当した、自分以外のメンバーの名前
    let executorNames: [String]

    var displayRepresentation: DisplayRepresentation {
        // 家事とメンバーの名前はユーザーが入力した文字なので翻訳しない
        .init(
            title: "\(title)",
            subtitle: "\(executorNames.formatted(.list(type: .and)))"
        )
    }

}

extension ThanksTargetEntity {

    init(_ candidate: ThanksCandidate) {
        self.init(id: candidate.id, title: candidate.title, executorNames: candidate.executorNames)
    }

}

/// ありがとうを伝えられる家事から選ぶ
struct ThanksTargetQuery: EntityStringQuery {

    @Dependency var environment: AppIntentEnvironment

    func entities(for identifiers: [String]) async throws -> [ThanksTargetEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ThanksTargetEntity] {
        try await environment.houseworkService
            .thanksCandidates(now: .now)
            .map(ThanksTargetEntity.init)
    }

    func entities(matching string: String) async throws -> [ThanksTargetEntity] {
        try await suggestedEntities().filter { $0.title.localizedStandardContains(string) }
    }

}
