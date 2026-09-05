//
//  CohabitantInvitationLink.swift
//  LocalPackage
//

import Foundation

/// 同居人グループへの招待リンク（Universal Link）の生成・解析を行う
///
/// リンクの形式は `https://<host>/invite/<token>`。
/// クエリではなくパスに載せることで、AASAの`components`とHostingのrewriteを単純にしている。
public enum CohabitantInvitationLink {

    /// 招待リンクのパスコンポーネント
    static let invitePathComponent = "invite"

    /// 開発環境のホスト（Firebase Hosting）
    static let developmentHost = "homete-ios-dev-e3ef7.web.app"

    /// 本番環境のホスト（Firebase Hosting）
    static let productionHost: String? = "homete-ios-dev.web.app"

    /// 現在のビルド構成に対応するホスト
    public static var host: String? {
        #if DEBUG
        developmentHost
        #else
        productionHost
        #endif
    }

    /// 招待リンクを利用できるビルドかどうか
    /// - Note: ホスト未設定の環境では共有導線自体を出さない
    public static var isAvailable: Bool {
        host != nil
    }

    /// 招待トークンから共有用のURLを生成する
    /// - Parameter token: 招待トークン
    /// - Returns: 招待リンクのURL（ホスト未設定の場合はnil）
    public static func url(token: String) -> URL? {
        guard let host, !token.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/\(invitePathComponent)/\(token)"
        return components.url
    }

    /// Universal Linkから招待トークンを取り出す
    /// - Parameter url: OSから渡されたURL
    /// - Returns: 招待トークン（招待リンクでない場合はnil）
    public static func token(from url: URL) -> String? {
        guard let host,
              url.scheme == "https",
              url.host() == host else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count == 2,
              pathComponents[0] == invitePathComponent,
              !pathComponents[1].isEmpty else { return nil }

        return pathComponents[1]
    }

}
