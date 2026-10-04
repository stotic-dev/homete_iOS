//
//  CohabitantRegistrationMessage.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import Foundation

public struct CohabitantRegistrationMessage: Codable, Equatable, Sendable {

    /// 現在の登録方式のバージョン
    /// - Note: 1（フィールド無し）はリーダーがクライアントから同居人グループを作る旧方式。
    ///         2は招待トークンでフォロワー自身が参加する方式（ADR-0040）。方式が違う端末どうしでは登録を進められない
    public static let currentProtocolVersion = 2

    public let type: CommunicateType
    /// 送信元の登録方式のバージョン
    /// - Note: 旧バージョンのアプリは送ってこないためnilになる。旧バージョンのアプリは知らないキーを読み飛ばすので、
    ///         このフィールドを足しても相手の解読は失敗しない
    public let protocolVersion: Int?

    public enum CommunicateType: Codable, Equatable, Sendable {

        /// 登録を行うメンバーが確定したかどうかの確認
        case fixedMember(isOK: Bool)
        /// 役割の共有
        case preRegistration(role: CohabitantRegistrationRole)
        /// 招待トークンの共有
        case shareInvitation(token: String)
        /// 登録完了したかどうかの確認
        case complete

    }

    /// 登録メンバーが確定したかどうか
    public var isFixedMember: Bool? {
        guard case let .fixedMember(isOK) = type else {
            return nil
        }
        return isOK
    }

    /// メンバーの役割
    public var memberRole: CohabitantRegistrationRole? {
        guard case let .preRegistration(role) = type else {
            return nil
        }
        return role
    }

    /// 招待トークン
    public var invitationToken: String? {
        guard case let .shareInvitation(token) = type else {
            return nil
        }
        return token
    }

    /// 登録処理が完了したかどうか
    public var isComplete: Bool? {
        guard case .complete = type else {
            return nil
        }
        return true
    }

    public func encodedData() -> Data {
        guard let encodedData = try? JSONEncoder().encode(self) else {
            preconditionFailure("Invalid message structure(\(self)).")
        }
        return encodedData
    }

    /// 登録方式が自分より古い端末からのメッセージかどうか
    public var isFromOutdatedPeer: Bool {
        (protocolVersion ?? 1) < Self.currentProtocolVersion
    }

    public init(type: CommunicateType, protocolVersion: Int? = Self.currentProtocolVersion) {
        self.type = type
        self.protocolVersion = protocolVersion
    }

}

public extension CohabitantRegistrationMessage {

    /// 受信したデータをメッセージに復元する
    /// - Note: 相手のアプリのバージョンが違うと、知らない種類のメッセージが届くことがある。
    ///         相手の端末から届くデータで落ちないよう、解読できない場合はnilを返して呼び出し側で捨てる
    init?(_ data: Data) {
        guard let message = try? JSONDecoder().decode(CohabitantRegistrationMessage.self, from: data) else {
            return nil
        }
        self = message
    }

}
