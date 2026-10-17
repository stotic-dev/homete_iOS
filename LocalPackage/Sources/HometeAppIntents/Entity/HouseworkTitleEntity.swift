//
//  HouseworkTitleEntity.swift
//  LocalPackage
//

import AppIntents
import Foundation

/// 完了にする家事を、家事の名前で表すEntity
///
/// 家事は日ごとに別のIDで作られるため、IDで表すとドネーションした翌日の提案が終わった家事を指してしまう。
/// 毎日の家事は名前が変わらないので、名前をIDにして翌日も同じ提案を使えるようにする
/// （[ADR-0044](doc/adr/0044-app-intents-headless-usecase-and-title-keyed-entity.md)）。
public struct HouseworkTitleEntity: AppEntity {

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "家事"
    public static let defaultQuery = HouseworkTitleQuery()

    /// 家事の名前
    public let id: String

    public var displayRepresentation: DisplayRepresentation {
        // 家事の名前はユーザーが入力した文字なので翻訳しない
        .init(title: "\(id)")
    }

}

/// 今日の未完了の家事の名前から、完了にする家事を選ぶ
public struct HouseworkTitleQuery: EntityStringQuery {

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    /// 名前がIDなので、サーバーに問い合わせずにそのまま返す。家事があるかは実行時に確かめる
    public func entities(for identifiers: [String]) async throws -> [HouseworkTitleEntity] {
        identifiers.map(HouseworkTitleEntity.init(id:))
    }

    public func suggestedEntities() async throws -> [HouseworkTitleEntity] {
        try await environment.resolveEntities {
            try await environment.houseworkService
                .incompleteTitles(now: .now)
                .map(HouseworkTitleEntity.init(id:))
        }
    }

    public func entities(matching string: String) async throws -> [HouseworkTitleEntity] {
        try await suggestedEntities().filter { $0.id.localizedStandardContains(string) }
    }

}
