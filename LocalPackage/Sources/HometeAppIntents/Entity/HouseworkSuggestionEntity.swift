//
//  HouseworkSuggestionEntity.swift
//  LocalPackage
//

import AppIntents
import Foundation
import HometeDomain

/// 声で伝えた家事の名前から、記録・登録する家事として提案する候補
///
/// 似ているいつもの家事と、話した名前のまま新しく登録する候補を並べ、Siriの聞き返しで選んでもらう。
struct HouseworkSuggestionEntity: AppEntity {

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "家事の候補"
    static let defaultQuery = HouseworkSuggestionQuery()

    let target: VoiceHouseworkTarget

    /// 候補の種類と、取り直さずに戻せるよう家事の名前を含める（いつもの家事は`frequent:<ID>:<名前>`）
    /// - Note: 聞き返しの間にいつもの家事が消されても、IDから候補に戻せるようにする。FirestoreのIDには`:`が入らない
    var id: String {
        switch target {
        case let .today(title):
            "\(Self.todayPrefix)\(title)"

        case let .frequent(id, title):
            "\(Self.frequentPrefix)\(id):\(title)"

        case let .title(title):
            "\(Self.titlePrefix)\(title)"
        }
    }

    var displayRepresentation: DisplayRepresentation {
        switch target {
        case let .today(title), let .frequent(_, title):
            // 家事の名前はユーザーが入力した文字なので翻訳しない
            .init(title: "\(title)")

        case let .title(title):
            .init(title: .localized("「\(title)」を新しく登録する"))
        }
    }

}

extension HouseworkSuggestionEntity {

    static let todayPrefix = "today:"
    static let frequentPrefix = "frequent:"
    static let titlePrefix = "title:"

    init(_ item: FrequentHouseworkItem) {
        self.init(target: .frequent(id: item.id, title: item.title))
    }

    /// IDから候補に戻す
    init?(id: String) {
        if id.hasPrefix(Self.todayPrefix) {
            self.init(target: .today(title: String(id.dropFirst(Self.todayPrefix.count))))
        } else if id.hasPrefix(Self.frequentPrefix) {
            let body = id.dropFirst(Self.frequentPrefix.count)
            guard let separator = body.firstIndex(of: ":") else { return nil }
            let itemId = String(body[..<separator])
            let title = String(body[body.index(after: separator)...])
            self.init(target: .frequent(id: itemId, title: title))
        } else if id.hasPrefix(Self.titlePrefix) {
            self.init(target: .title(String(id.dropFirst(Self.titlePrefix.count))))
        } else {
            return nil
        }
    }

}

/// 記録・登録する家事の候補を、いつもの家事から選ぶ
struct HouseworkSuggestionQuery: EntityQuery {

    @Dependency var environment: AppIntentEnvironment

    /// IDに名前を含めているので、サーバーに問い合わせずにそのまま戻す。家事があるかは実行時に確かめる
    func entities(for identifiers: [String]) async throws -> [HouseworkSuggestionEntity] {
        identifiers.compactMap(HouseworkSuggestionEntity.init(id:))
    }

    func suggestedEntities() async throws -> [HouseworkSuggestionEntity] {
        try await environment.resolveEntities {
            try await environment.houseworkService.frequentItems().map(HouseworkSuggestionEntity.init)
        }
    }

}
