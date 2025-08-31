//
//  CohabitantRegistrationMessageTests.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/31.
//

import Foundation
import Testing
@testable import homete

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
            .preRegistration(role: .follower(accountId: "id")),
            .shareCohabitantId(id: "id")
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
            .follower(accountId: "id")
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
            .shareCohabitantId(id: "id")
        ]
    )
    func memberRole_typeIsNotPreRegistration(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        
        let message = CohabitantRegistrationMessage(type: inputMessageType)
        
        let actual = message.memberRole
        
        #expect(actual == nil)
    }
    
    @Test("同居人ID共有メッセージの場合、共有された同居人IDを取得できる")
    func cohabitantId_typeIsShareCohabitantId() {
        
        let inputId = "test_id"
        let message = CohabitantRegistrationMessage(type: .shareCohabitantId(id: inputId))
        
        let actual = message.cohabitantId
        
        #expect(actual == inputId)
    }
    
    @Test(
        "同居人ID共有メッセージ以外の場合、nilを返す",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .preRegistration(role: .lead),
            .preRegistration(role: .follower(accountId: "id")),
            .fixedMember(isOK: true)
        ]
    )
    func cohabitantId_typeIsNotShareCohabitantId(
        inputMessageType: CohabitantRegistrationMessage.CommunicateType
    ) {
        
        let message = CohabitantRegistrationMessage(type: inputMessageType)
        
        let actual = message.cohabitantId
        
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
            .preRegistration(role: .follower(accountId: "id")),
            .fixedMember(isOK: true),
            .shareCohabitantId(id: "id")
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
            .preRegistration(role: .follower(accountId: "id")),
            .shareCohabitantId(id: "id")
        ]
    )
    func encodeDecode(type: CohabitantRegistrationMessage.CommunicateType) throws {
        
        let message = CohabitantRegistrationMessage(type: type)
        
        let actual = message.encodedData()
        
        let expected = try JSONEncoder().encode(message)
        #expect(actual == expected)
    }
    
    @Test(
        "JSONエンコードされた同居人登録のメッセージを元の形式のでコードできること",
        arguments: [
            CohabitantRegistrationMessage.CommunicateType.complete,
            .fixedMember(isOK: true),
            .fixedMember(isOK: false),
            .preRegistration(role: .lead),
            .preRegistration(role: .follower(accountId: "id")),
            .shareCohabitantId(id: "id")
        ]
    )
    func init_withValidData(type: CohabitantRegistrationMessage.CommunicateType) throws {
        
        let message = CohabitantRegistrationMessage(type: type)
        let encodedData = try JSONEncoder().encode(message)
        
        let actual = CohabitantRegistrationMessage(encodedData)
        
        #expect(actual == message)
    }
}
