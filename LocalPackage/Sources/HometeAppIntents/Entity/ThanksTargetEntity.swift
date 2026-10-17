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

    /// 候補から外れた家事（送信済み・未完了に戻されたなど）も、名前の無いEntityとして返す
    ///
    /// 返さないと、家事を指定して実行したときにIntentへたどり着く前に失敗し、Siriには汎用の失敗が出る。
    /// Intentの実行時に伝えられるかを確かめ、伝えられない理由をユーザーに伝える。
    func entities(for identifiers: [String]) async throws -> [ThanksTargetEntity] {
        let candidates = try await suggestedEntities()
        return identifiers.map { id in
            candidates.first { $0.id == id } ?? .init(id: id, title: "", executorNames: [])
        }
    }

    func suggestedEntities() async throws -> [ThanksTargetEntity] {
        try await environment.resolveEntities {
            try await environment.houseworkService
                .thanksCandidates(now: .now)
                .map(ThanksTargetEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [ThanksTargetEntity] {
        try await suggestedEntities().filter { $0.title.localizedStandardContains(string) }
    }

}
