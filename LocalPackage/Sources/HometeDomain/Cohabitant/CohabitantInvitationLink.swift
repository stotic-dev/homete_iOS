//
//  CohabitantInvitationLink.swift
//  LocalPackage
//

import Foundation

/// 同居人グループへの招待リンクの生成・解析を行う
///
/// 共有するのは Universal Link（`https://<host>/invite/<token>?openExternalBrowser=1`）。
/// クエリではなくパスに載せることで、AASAの`components`とHostingのrewriteを単純にしている。
/// WebView（LINE等）では Universal Link が発火しないため、着地ページの「アプリで開く」は
/// カスタムURLスキーム（`<customScheme>://invite/<token>`）で起動する。解析はどちらの形式も受け付ける。
public enum CohabitantInvitationLink {

    /// 招待リンクのパスコンポーネント
    static let invitePathComponent = "invite"

    /// LINEに外部ブラウザ（Safari）でリンクを開かせるためのクエリ
    /// - Note: 他のアプリはこのクエリを無視するため、共有先を問わず常に付与する
    static let openExternalBrowserQueryItem = URLQueryItem(name: "openExternalBrowser", value: "1")

    /// 開発環境のホスト（Firebase Hosting）
    static let developmentHost = "homete-ios-dev-e3ef7.web.app"

    /// 本番環境のホスト（Firebase Hosting）
    static let productionHost: String? = "homete-ios-dev.web.app"

    /// 開発環境のカスタムURLスキーム
    static let developmentCustomScheme = "homeau-dev"

    /// 本番環境のカスタムURLスキーム
    static let productionCustomScheme = "homeau"

    /// 現在のビルド構成に対応するホスト
    public static var host: String? {
        #if DEBUG
        developmentHost
        #else
        productionHost
        #endif
    }

    /// 現在のビルド構成に対応するカスタムURLスキーム
    /// - Note: メインターゲットの Build Setting `INVITE_URL_SCHEME`（`Info.plist`の`CFBundleURLSchemes`）と
    ///         一致させること。Stg（TestFlight）はDEBUGが定義され開発ホストを向くため、スキームも開発用になる
    public static var customScheme: String {
        #if DEBUG
        developmentCustomScheme
        #else
        productionCustomScheme
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
        components.queryItems = [openExternalBrowserQueryItem]
        return components.url
    }

    /// OSから渡されたURLから招待トークンを取り出す
    /// - Parameter url: OSから渡されたURL
    /// - Returns: 招待トークン（招待リンクでない場合はnil）
    public static func token(from url: URL) -> String? {
        switch source(of: url) {
        case .universalLink:
            // https://<host>/invite/<token>[?...]
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard pathComponents.count == 2,
                  pathComponents[0] == invitePathComponent else { return nil }
            return nonEmpty(pathComponents[1])

        case .customScheme:
            // <customScheme>://invite/<token> はホストが"invite"、パスがトークンになる
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard url.host() == invitePathComponent,
                  pathComponents.count == 1 else { return nil }
            return nonEmpty(pathComponents[0])

        // クリップボード経由はURL自体の形式ではないため、source(of:)がこの値を返すことはない
        case .pasteboard, nil:
            return nil
        }
    }

    /// URLがどの経路の招待リンクかを判定する
    /// - Parameter url: OSから渡されたURL
    /// - Returns: 起動経路（招待リンクのホスト・スキームでなければnil）
    public static func source(of url: URL) -> CohabitantInvitationOpenSource? {
        if let host, url.scheme == "https", url.host() == host {
            return .universalLink
        }
        if url.scheme == customScheme {
            return .customScheme
        }
        return nil
    }

}

private extension CohabitantInvitationLink {

    static func nonEmpty(_ token: String) -> String? {
        token.isEmpty ? nil : token
    }

}

/// 招待リンクでアプリが起動した経路
public enum CohabitantInvitationOpenSource: String, Equatable, Sendable {

    /// Universal Link（`https`）。メモアプリやSafariなど、AASAの照合が行われる経路
    case universalLink = "universal_link"
    /// カスタムURLスキーム。WebViewで開かれた着地ページの「アプリで開く」
    case customScheme = "custom_scheme"
    /// クリップボードにコピーされた招待リンクを読み取った
    case pasteboard

}
