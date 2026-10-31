//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

/// - Note: FCMトークンはここに持たない。同じグループのメンバーがAccountを読めるため、
///         本人だけが読める`Account/{uid}/Private/fcm`へ分けている（#241）
public struct Account: Equatable, Codable, Sendable {

    public let id: String
    public let userName: String
    public let cohabitantId: String?
    /// プレミアムプランに加入しているか
    /// - Note: RevenueCatのWebhookを受けたCloud Functionsだけが書き、アプリからは書かない（Firestoreルールで拒否される）。
    ///         家事データの保持期間をサーバー側で判定するための値で、機能の解放判定にはクライアントのエンタイトルメントを使う。
    public let isPremium: Bool

    public init(
        id: String,
        userName: String,
        cohabitantId: String?,
        isPremium: Bool = false
    ) {
        self.id = id
        self.userName = userName
        self.cohabitantId = cohabitantId
        self.isPremium = isPremium
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userName = try container.decode(String.self, forKey: .userName)
        cohabitantId = try container.decodeIfPresent(String.self, forKey: .cohabitantId)
        // isPremium 導入前に作成されたドキュメントにはフィールドが存在しないため、無い場合は無料プラン扱いにする
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
    }

}
