//
//  CohabitantRegistrationMessageTests.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/31.
//

import Foundation
@testable import HometeDomain
import Testing

struct CohabitantRegistrationMessageTests {

    @Test(
        "メンバー確認のメッセージの場合、メンバー確定するかどうかが取得できること",
        arguments: [true, false]
    )
    func isFixedMember_typeIsFixedMember(input: Bool) {
        let message = CohabitantRegistrationMessage(type: .fixedMember(isOK: input))

        let actual = message.isFixedMember

        #expect(actual == input)
    }

    @Test(
        "メンバー確認のメッセージ以外の場合、nilを返す",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .preRegistration(role: .lead),
            .preRegistration(role: .follower),
            .shareInvitation(token: "token")
        ]
    )
    func isFixedMember_typeIsNotFixedMember(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        let message = CohabitantRegistrationMessage(type: inputMessageType)

        let actual = message.isFixedMember

        #expect(actual == nil)
    }

    @Test(
        "登録処理開始前のメッセージの場合、送信者の役割を取得できる",
        arguments: [
            CohabitantRegistrationRole.lead,
            .follower
        ]
    )
    func memberRole_typeIsPreRegistration(inputRole: CohabitantRegistrationRole) {
        let message = CohabitantRegistrationMessage(type: .preRegistration(role: inputRole))

        let actual = message.memberRole

        #expect(actual == inputRole)
    }

    @Test(
        "登録処理開始前のメッセージ以外の場合、nilを返す",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .fixedMember(isOK: true),
            .shareInvitation(token: "token")
        ]
    )
    func memberRole_typeIsNotPreRegistration(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        let message = CohabitantRegistrationMessage(type: inputMessageType)

        let actual = message.memberRole

        #expect(actual == nil)
    }

    @Test("招待トークン共有メッセージの場合、共有された招待トークンを取得できる")
    func invitationToken_typeIsShareInvitation() {
        let inputToken = "test_token"
        let message = CohabitantRegistrationMessage(type: .shareInvitation(token: inputToken))

        let actual = message.invitationToken

        #expect(actual == inputToken)
    }

    @Test(
        "招待トークン共有メッセージ以外の場合、nilを返す",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .preRegistration(role: .lead),
            .preRegistration(role: .follower),
            .fixedMember(isOK: true)
        ]
    )
    func invitationToken_typeIsNotShareInvitation(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        let message = CohabitantRegistrationMessage(type: inputMessageType)

        let actual = message.invitationToken

        #expect(actual == nil)
    }

    @Test("登録処理完了メッセージの場合、完了かどうかを取得する")
    func isComplete_typeIsComplete() {
        let message = CohabitantRegistrationMessage(type: .complete)

        let actual = message.isComplete

        #expect(actual == true)
    }

    @Test(
        "登録処理完了メッセージ以外の場合、nilを返す",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.preRegistration(role: .lead),
            .preRegistration(role: .follower),
            .fixedMember(isOK: true),
            .shareInvitation(token: "token")
        ]
    )
    func isComplete_typeIsNotComplete_returnsNil(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        let message = CohabitantRegistrationMessage(type: inputMessageType)

        let actual = message.isComplete

        #expect(actual == nil)
    }

    @Test(
        "同居人登録のメッセージはJSONエンコードされたDataが送信されること",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .fixedMember(isOK: true),
            .fixedMember(isOK: false),
            .preRegistration(role: .lead),
            .preRegistration(role: .follower),
            .shareInvitation(token: "token")
        ]
    )
    func encodeDecode(type: CohabitantRegistrationMessage.CommunicateType) throws {
        let message = CohabitantRegistrationMessage(type: type)

        let encodedData = message.encodedData()

        // JSONのキーの並びは保証されないため、バイト列ではなく解読した結果で比べる
        let actual = try JSONDecoder().decode(CohabitantRegistrationMessage.self, from: encodedData)
        #expect(actual == message)
    }

    @Test(
        "JSONエンコードされた同居人登録のメッセージを元の形式のでコードできること",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .fixedMember(isOK: true),
            .fixedMember(isOK: false),
            .preRegistration(role: .lead),
            .preRegistration(role: .follower),
            .shareInvitation(token: "token"),
        ]
    )
    func init_withValidData(type: CohabitantRegistrationMessage.CommunicateType) throws {
        let message = CohabitantRegistrationMessage(type: type)
        let encodedData = try JSONEncoder().encode(message)

        let actual = CohabitantRegistrationMessage(encodedData)

        #expect(actual == message)
    }

    @Test("旧バージョンのアプリが送るバージョン無しのメッセージは、バージョン無しとして解読できる")
    func init_withLegacyData() {
        let data = Data(#"{"type":{"fixedMember":{"isOK":true}}}"#.utf8)
        let expected = CohabitantRegistrationMessage(type: .fixedMember(isOK: true), protocolVersion: nil)

        let actual = CohabitantRegistrationMessage(data)

        #expect(actual == expected)
    }

    @Test(
        "登録方式のバージョンが現在より古いか、無い場合は古い端末からのメッセージと判定する",
        arguments: [
            (Int?.none, true),
            (1, true),
            (CohabitantRegistrationMessage.currentProtocolVersion, false),
        ]
    )
    func isFromOutdatedPeer(protocolVersion: Int?, expected: Bool) {
        let message = CohabitantRegistrationMessage(type: .complete, protocolVersion: protocolVersion)

        let actual = message.isFromOutdatedPeer

        #expect(actual == expected)
    }

    @Test(
        "メンバー確認のメッセージは、旧バージョンのアプリの形式でも解読できる",
        arguments: [true, false]
    )
    func encodedFixedMember_decodableByLegacyApp(isOK: Bool) throws {
        // 旧バージョンのアプリは、メンバー確認の段階で相手のバージョンを判定するために受け取る。
        // ここで解読に失敗すると、旧バージョンのアプリはpreconditionFailureで落ちる
        let message = CohabitantRegistrationMessage(type: .fixedMember(isOK: isOK))
        let expected = LegacyMessage(type: .fixedMember(isOK: isOK))

        let actual = try JSONDecoder().decode(LegacyMessage.self, from: message.encodedData())

        #expect(actual == expected)
    }

    @Test("解読できないデータの場合、nilを返す")
    func init_withInvalidData() {
        // 相手のアプリのバージョンが新しく、知らない種類のメッセージが届いたケース
        let data = Data(#"{"type":{"unknownType":{}}}"#.utf8)

        let actual = CohabitantRegistrationMessage(data)

        #expect(actual == nil)
    }

}

/// 旧バージョン（v1.0.x）のアプリが持つメッセージの形式
private struct LegacyMessage: Decodable, Equatable {

    let type: LegacyCommunicateType

}

private enum LegacyCommunicateType: Decodable, Equatable {

    case fixedMember(isOK: Bool)
    case preRegistration(role: LegacyRole)
    case shareCohabitantId(id: String)
    case complete

}

private enum LegacyRole: Decodable, Equatable {

    case follower(accountId: String)
    case lead

}
