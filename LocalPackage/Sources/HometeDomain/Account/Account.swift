//
//  Account.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

public struct Account: Equatable, Codable, Sendable {

    public let id: String
    public let userName: String
    public let fcmToken: String?
    public let cohabitantId: String?
    /// プレミアムプランに加入しているか
    /// - Note: 家事データの保持期間をサーバー側で判定するために保存する。
    ///         機能の解放判定にはクライアントのエンタイトルメントを使うため、この値は保持期間の決定にのみ使う。
    public let isPremium: Bool

    public init(
        id: String,
        userName: String,
        fcmToken: String?,
        cohabitantId: String?,
        isPremium: Bool = false
    ) {
        self.id = id
        self.userName = userName
        self.fcmToken = fcmToken
        self.cohabitantId = cohabitantId
        self.isPremium = isPremium
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userName = try container.decode(String.self, forKey: .userName)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        cohabitantId = try container.decodeIfPresent(String.self, forKey: .cohabitantId)
        // isPremium 導入前に作成されたドキュメントにはフィールドが存在しないため、無い場合は無料プラン扱いにする
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
    }

    /// プレミアム加入状態のみを差し替えたアカウントを返す
    public func updateIsPremium(_ isPremium: Bool) -> Self {
        .init(
            id: id,
            userName: userName,
            fcmToken: fcmToken,
            cohabitantId: cohabitantId,
            isPremium: isPremium
        )
    }

}

public extension Account {

    static func initial(auth: AccountAuthResult, userName: UserName, fcmToken: String?) -> Self {
        .init(id: auth.id, userName: userName.value, fcmToken: fcmToken, cohabitantId: nil)
    }

}
