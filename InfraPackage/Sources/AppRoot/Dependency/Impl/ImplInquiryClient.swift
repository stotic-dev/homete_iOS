//
//  ImplInquiryClient.swift
//

import FirebaseFunctions
import Foundation
import HometeDomain
import HometeInfrastructure

extension InquiryClient {

    static let liveValue: InquiryClient = .init { request in
        var parameters: [String: Any] = [
            "requestId": request.requestId,
            "category": request.category.rawValue,
            "body": request.body,
            "appVersion": InquiryClientEnvironment.appVersion,
            "osVersion": InquiryClientEnvironment.osVersion,
        ]
        if let deviceModel = InquiryClientEnvironment.deviceModel {
            parameters["deviceModel"] = deviceModel
        }
        return try await call("createinquiry", parameters: parameters, transform: makePostResult)
    } list: { cursor in
        var parameters: [String: Any] = [:]
        if let cursor {
            parameters["cursor"] = cursor
        }
        return try await call("listinquiries", parameters: parameters, transform: makeListPage)
    } fetch: { inquiryId, cursor in
        var parameters: [String: Any] = ["inquiryId": inquiryId]
        if let cursor {
            parameters["cursor"] = cursor
        }
        return try await call("fetchinquiry", parameters: parameters, transform: makeDetailPage)
    } sendMessage: { inquiryId, requestId, body in
        try await call(
            "sendinquirymessage",
            parameters: ["inquiryId": inquiryId, "requestId": requestId, "body": body],
            transform: makePostResult
        )
    } markRead: { inquiryId, messageId in
        try await call(
            "markinquiryread",
            parameters: ["inquiryId": inquiryId, "messageId": messageId]
        ) { data in
            guard let response = data as? [String: Any] else { throw DomainError.other }
            return try makeInquiry(from: response["inquiry"])
        }
    }

}

private extension InquiryClient {

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

    static func makeListPage(from data: Any) throws -> InquiryListPage {
        guard let response = data as? [String: Any],
              let inquiries = response["inquiries"] as? [Any],
              let unreadCount = response["unreadCount"] as? Int else {
            throw DomainError.other
        }

        return try InquiryListPage(
            inquiries: inquiries.map(makeInquiry),
            // 最後のページはnull（NSNull）で返るため、Stringにキャストできなければnil
            nextCursor: response["nextCursor"] as? String,
            unreadCount: unreadCount
        )
    }

    static func makeDetailPage(from data: Any) throws -> InquiryDetailPage {
        guard let response = data as? [String: Any],
              let messages = response["messages"] as? [Any] else {
            throw DomainError.other
        }

        return try InquiryDetailPage(
            inquiry: makeInquiry(from: response["inquiry"]),
            messages: messages.map(makeMessage),
            // 最も古いメッセージまで返した場合はnull（NSNull）で返るため、Stringにキャストできなければnil
            nextCursor: response["nextCursor"] as? String
        )
    }

    static func makePostResult(from data: Any) throws -> InquiryPostResult {
        guard let response = data as? [String: Any] else { throw DomainError.other }

        return try InquiryPostResult(
            inquiry: makeInquiry(from: response["inquiry"]),
            message: makeMessage(from: response["message"])
        )
    }

    static func makeInquiry(from data: Any?) throws -> Inquiry {
        guard let response = data as? [String: Any],
              let id = response["id"] as? String,
              let category = (response["category"] as? String).flatMap(InquiryCategory.init),
              let status = (response["status"] as? String).flatMap(InquiryStatus.init),
              let createdAt = makeDate(from: response["createdAt"]),
              let updatedAt = makeDate(from: response["updatedAt"]),
              let lastMessageAt = makeDate(from: response["lastMessageAt"]),
              let lastMessageSender = (response["lastMessageSender"] as? String).flatMap(InquiryMessageSender.init),
              let hasUnreadReply = response["hasUnreadReply"] as? Bool,
              let messageCount = response["messageCount"] as? Int else {
            throw DomainError.other
        }

        return Inquiry(
            id: id,
            category: category,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastMessageAt: lastMessageAt,
            lastMessageSender: lastMessageSender,
            hasUnreadReply: hasUnreadReply,
            messageCount: messageCount
        )
    }

    static func makeMessage(from data: Any?) throws -> InquiryMessage {
        guard let response = data as? [String: Any],
              let id = response["id"] as? String,
              let sender = (response["sender"] as? String).flatMap(InquiryMessageSender.init),
              let body = response["body"] as? String,
              let createdAt = makeDate(from: response["createdAt"]) else {
            throw DomainError.other
        }

        return InquiryMessage(id: id, sender: sender, body: body, createdAt: createdAt)
    }

    /// Functions側はepochミリ秒で返すため秒に直す
    static func makeDate(from value: Any?) -> Date? {
        guard let milliseconds = value as? Double else { return nil }
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }

    /// FunctionsのHttpsErrorをドメインのエラーに変換する
    ///
    /// 問い合わせ固有の失敗かどうかはFunctionsが`details`に載せたコードだけで判別する。
    /// 標準のエラーコードで判別すると、関数が未デプロイのときの`notFound`を
    /// 問い合わせが見つからないものとして扱ってしまうため。
    static func convert(_ error: any Error) -> any Error {
        let nsError = error as NSError
        guard nsError.domain == FunctionsErrorDomain else { return error }

        if let details = nsError.userInfo[FunctionsErrorDetailsKey] as? [String: Any],
           let serverCode = details[InquiryError.serverCodeKey] as? String {
            if let inquiryError = InquiryError(serverCode: serverCode) {
                return inquiryError
            }
            // アカウントの削除が始まっている。再サインインの案内が出る認証エラーとして扱う
            if serverCode == InquiryError.accountDeletedServerCode {
                return DomainError.failAuth
            }
        }

        guard let code = FunctionsErrorCode(rawValue: nsError.code) else { return error }

        switch code {
        case .unavailable, .deadlineExceeded:
            // 問い合わせ固有の情報が付かないこれらは、サーバに届いていないか応答が返らなかったケース
            return DomainError.noNetwork

        case .unauthenticated:
            return DomainError.failAuth

        default:
            return error
        }
    }

}

/// 問い合わせを作るときに一緒に送る、アプリと端末の情報
private enum InquiryClientEnvironment {

    /// 例: `1.4.0 (123)`。APIの上限（32文字）に収まるよう切り詰める
    static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return String("\(version) (\(build))".prefix(32))
    }

    /// 例: `iOS 26.1.0`
    static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// 例: `iPhone17,3`。取れなければ送らない
    static var deviceModel: String? {
        // シミュレータではホストのアーキテクチャ（arm64）が返るため、シミュレートしている機種を使う
        if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return String(simulatorModel.prefix(64))
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(bytes: buffer.prefix { $0 != 0 }, encoding: .utf8)
        }
        guard let machine, !machine.isEmpty else { return nil }
        return String(machine.prefix(64))
    }

}
