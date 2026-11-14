//
//  ImplAnnouncementClient.swift
//

import FirebaseFunctions
import Foundation
import HometeDomain
import HometeDomainUI
import HometeInfrastructure

extension AnnouncementClient {

    static let liveValue: AnnouncementClient = .init {
        try await call(
            "listannouncements",
            parameters: ["appVersion": AnnouncementClientEnvironment.appVersion],
            transform: makeList
        )
    } markRead: { announcementId, scope in
        try await call(
            "markannouncementsread",
            parameters: ["announcementId": announcementId, "scope": scope.rawValue]
        ) { _ in }
    }

}

private extension AnnouncementClient {

    static func call<T>(
        _ name: String,
        parameters: [String: Any],
        transform: (Any) throws -> T
    ) async throws -> T {
        do {
            let result = try await FunctionsService.call(name, parameters: parameters)
            return try transform(result.data)
        } catch {
            throw convert(error)
        }
    }

    static func makeList(from data: Any) throws -> AnnouncementList {
        guard let response = data as? [String: Any],
              let announcements = response["announcements"] as? [Any],
              let unreadCount = response["unreadCount"] as? Int else {
            throw DomainError.other
        }

        return try AnnouncementList(
            announcements: announcements.map(makeAnnouncement),
            unreadCount: unreadCount,
            // 出すものが無い場合はnull（NSNull）で返るため、Stringにキャストできなければnil
            modalAnnouncementId: response["modalAnnouncementId"] as? String
        )
    }

    static func makeAnnouncement(from data: Any) throws -> Announcement {
        guard let response = data as? [String: Any],
              let id = response["id"] as? String,
              let title = response["title"] as? String,
              let body = response["body"] as? String,
              let publishedAt = makeDate(from: response["publishedAt"]),
              let updatedAt = makeDate(from: response["updatedAt"]),
              let isUnread = response["isUnread"] as? Bool else {
            throw DomainError.other
        }

        return Announcement(
            id: id,
            title: title,
            body: body,
            linkUrl: makeLinkUrl(from: response["linkUrl"]),
            publishedAt: publishedAt,
            updatedAt: updatedAt,
            isUnread: isUnread
        )
    }

    /// リンクはhttpsのURLだけを開く。それ以外（null・形式違反）はリンクが無いものとして扱う
    static func makeLinkUrl(from value: Any?) -> URL? {
        guard let string = value as? String,
              let url = URL(string: string),
              url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    /// Functions側はepochミリ秒で返すため秒に直す
    static func makeDate(from value: Any?) -> Date? {
        guard let milliseconds = value as? Double else { return nil }
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }

    /// FunctionsのHttpsErrorをドメインのエラーに変換する
    ///
    /// お知らせ固有の失敗かどうかはFunctionsが`details`に載せたコードだけで判別する。
    /// 標準のエラーコードで判別すると、関数が未デプロイのときの`notFound`を
    /// お知らせが見つからないものとして扱ってしまうため。
    static func convert(_ error: any Error) -> any Error {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain else { return error }

        if let details = nsError.userInfo[FunctionsErrorDetailsKey] as? [String: Any],
           let serverCode = details[AnnouncementError.serverCodeKey] as? String,
           let announcementError = AnnouncementError(serverCode: serverCode) {
            return announcementError
        }

        guard let code = FunctionsErrorCode(rawValue: nsError.code) else { return error }

        switch code {
        case .unavailable, .deadlineExceeded:
            // お知らせ固有の情報が付かないこれらは、サーバに届いていないか応答が返らなかったケース
            return DomainError.noNetwork

        case .unauthenticated:
            return DomainError.failAuth

        default:
            return error
        }
    }

}

/// お知らせを取得するときに送る、アプリの情報
private enum AnnouncementClientEnvironment {

    /// 例: `1.4.0`。配信対象のバージョンの判定に使うため、ビルド番号は付けない
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

}
