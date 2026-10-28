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
    /// - Note: 家事データの保持期間をサーバー側で判定するために保存する。
    ///         機能の解放判定にはクライアントのエンタイトルメントを使うため、この値は保持期間の決定にのみ使う。
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

    /// プレミアム加入状態のみを差し替えたアカウントを返す
    public func updateIsPremium(_ isPremium: Bool) -> Self {
        .init(
            id: id,
            userName: userName,
            cohabitantId: cohabitantId,
            isPremium: isPremium
        )
    }

}
