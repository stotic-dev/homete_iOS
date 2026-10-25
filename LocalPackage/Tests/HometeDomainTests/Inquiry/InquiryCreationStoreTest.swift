//
//  InquiryCreationStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct InquiryCreationStoreTest {

    @Test("種別と本文を送って問い合わせを作ると、作った問い合わせを返して入力を空にする")
    func submit_success() async {
        // Arrange
        let requests = TestLockedArray<InquiryCreationRequest>()
        let sut = InquiryCreationStore(
            inquiryClient: .init(create: { request in
                await requests.append(request)
                return .init(inquiry: .makeForTest(id: "created"), message: .makeForTest(id: "message"))
            }),
            makeRequestId: { "request-1" }
        )
        sut.category = .bug
        sut.submission.body = "動きません"

        // Act
        let actual = await sut.submit()

        // Assert
        #expect(actual == .makeForTest(id: "created"))
        #expect(await requests.values == [.init(requestId: "request-1", category: .bug, body: "動きません")])
        #expect(sut.submission == InquirySubmission())
    }

    @Test("送信に失敗すると、入力と送信に使ったrequestIdを残して失敗の理由を入れる")
    func submit_failureKeepsInput() async {
        // Arrange
        let sut = InquiryCreationStore(
            inquiryClient: .init(create: { _ in throw InquiryError.rateLimited }),
            makeRequestId: { "request-1" }
        )
        sut.category = .usage
        sut.submission.body = "使い方を教えてください"

        // Act
        let actual = await sut.submit()

        // Assert
        #expect(actual == nil)
        let expected = InquirySubmission(
            body: "使い方を教えてください",
            failure: .rateLimited,
            requestId: "request-1"
        )
        #expect(sut.submission == expected)
    }

    @Test("失敗した後に送り直すと、前回と同じrequestIdで送る")
    func submit_retryUsesSameRequestId() async {
        // Arrange
        let requestIds = TestLockedArray<String>()
        let generatedCount = TestBox(value: 0)
        let shouldFail = TestBox(value: true)
        let sut = InquiryCreationStore(
            inquiryClient: .init(create: { request in
                await requestIds.append(request.requestId)
                if shouldFail.value {
                    throw DomainError.noNetwork
                }
                return .init(inquiry: .makeForTest(id: "created"), message: .makeForTest(id: "message"))
            }),
            makeRequestId: {
                generatedCount.value += 1
                return "request-\(generatedCount.value)"
            }
        )
        sut.category = .bug
        sut.submission.body = "動きません"
        _ = await sut.submit()
        shouldFail.value = false

        // Act
        _ = await sut.submit()

        // Assert
        #expect(await requestIds.values == ["request-1", "request-1"])
    }

    @Test("種別を選んでいないと送らない")
    func submit_withoutCategory() async {
        // Arrange
        let createCount = TestCounter()
        let sut = InquiryCreationStore(inquiryClient: .init(create: { _ in
            await createCount.increment()
            return .init(inquiry: .makeForTest(id: "created"), message: .makeForTest(id: "message"))
        }))
        sut.submission.body = "動きません"

        // Act
        let actual = await sut.submit()

        // Assert
        #expect(actual == nil)
        #expect(await createCount.value == 0)
    }

    @Test("空白だけの本文は送らない")
    func submit_blankBody() async {
        // Arrange
        let createCount = TestCounter()
        let sut = InquiryCreationStore(inquiryClient: .init(create: { _ in
            await createCount.increment()
            return .init(inquiry: .makeForTest(id: "created"), message: .makeForTest(id: "message"))
        }))
        sut.category = .bug
        sut.submission.body = "  \n"

        // Act
        let actual = await sut.submit()

        // Assert
        #expect(actual == nil)
        #expect(await createCount.value == 0)
    }

    @Test("送信中にもう一度送っても、二重には送らない")
    func submit_ignoresWhileSending() async {
        // Arrange
        let gate = TestGate()
        let createCount = TestCounter()
        let sut = InquiryCreationStore(inquiryClient: .init(create: { _ in
            await createCount.increment()
            await gate.wait()
            return .init(inquiry: .makeForTest(id: "created"), message: .makeForTest(id: "message"))
        }))
        sut.category = .bug
        sut.submission.body = "動きません"
        let firstSubmit = Task { await sut.submit() }
        await gate.waitUntilArrived()

        // Act
        let actual = await sut.submit()

        // Assert
        gate.open()
        _ = await firstSubmit.value
        #expect(actual == nil)
        #expect(await createCount.value == 1)
    }

}
