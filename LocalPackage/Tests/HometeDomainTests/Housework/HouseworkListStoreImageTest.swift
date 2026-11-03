// swiftlint:disable file_length
//
//  HouseworkListStoreImageTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkListStoreImageTest {

    /// 画像の実体と家事の参照への書き込みを、起きた順に記録する
    enum Operation: Equatable {

        case upload(storagePath: String, data: Data)
        case deleteFile(storagePath: String)
        case addReferences(houseworkId: String, images: [HouseworkImage], cohabitantId: String)
        case removeReference(houseworkId: String, image: HouseworkImage, cohabitantId: String)
        case insertItems([HouseworkItem], cohabitantId: String)

    }

    struct WriteError: Error {}

    static let cohabitantId = "cohabitantId"
    static let now = Date(timeIntervalSince1970: 1000)
    static let upload = HouseworkImageUpload(id: "image1", data: Data([0x01]))
    static let uploadedImage = HouseworkImage(
        id: "image1",
        storagePath: "Cohabitant/cohabitantId/Houseworks/id1/image1.jpg",
        uploaderId: "userA"
    )
    static let othersImage = HouseworkImage(
        id: "image0",
        storagePath: "Cohabitant/cohabitantId/Houseworks/id1/image0.jpg",
        uploaderId: "userB"
    )

    static func makeImageClient(
        _ operations: TestLockedArray<Operation>,
        uploadError: (any Error)? = nil
    ) -> HouseworkImageClient {
        .init(
            upload: { data, storagePath in
                if let uploadError { throw uploadError }
                await operations.append(.upload(storagePath: storagePath, data: data))
            },
            delete: { storagePath in
                await operations.append(.deleteFile(storagePath: storagePath))
            }
        )
    }

    // MARK: - 追加

    @Test("登録済みの家事に画像を添えると、実体を上げてから参照だけを書き足し、同居人には通知しない")
    func addImages_registered_uploadsThenAddsReferences() async throws {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now, images: [Self.othersImage])
        let store = HouseworkListStore(
            houseworkClient: .init(
                insertOrUpdateItemHandler: { _, _ in Issue.record() },
                addImagesHandler: { houseworkId, images, cohabitantId in
                    await operations.append(
                        .addReferences(houseworkId: houseworkId, images: images, cohabitantId: cohabitantId)
                    )
                }
            ),
            houseworkImageClient: Self.makeImageClient(operations),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            items: [.makeForTest(items: [item])]
        )

        // Act

        try await store.addImages(
            [Self.upload],
            target: item,
            cohabitantId: Self.cohabitantId,
            isRegistered: true,
            uploaderId: "userA",
            policy: .premium,
            step: .detail
        )

        // Assert

        let expectedOperations: [Operation] = [
            .upload(storagePath: Self.uploadedImage.storagePath, data: Self.upload.data),
            .addReferences(houseworkId: "id1", images: [Self.uploadedImage], cohabitantId: Self.cohabitantId),
        ]
        #expect(await operations.values == expectedOperations)
        #expect(logger.value == [.housework(.addImage(step: .detail, isSuccess: true))])
    }

    @Test("テンプレートから表示しているだけの家事に画像を添えると、実体を上げてから作成日時を付けてドキュメントごと作る")
    func addImages_notRegistered_insertsItem() async throws {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now)
        let store = HouseworkListStore(
            houseworkClient: .init(
                createItemsHandler: { items, cohabitantId in
                    await operations.append(.insertItems(items, cohabitantId: cohabitantId))
                },
                addImagesHandler: { _, _, _ in Issue.record() }
            ),
            houseworkImageClient: Self.makeImageClient(operations),
            now: { Self.now }
        )

        // Act

        try await store.addImages(
            [Self.upload],
            target: item,
            cohabitantId: Self.cohabitantId,
            isRegistered: false,
            uploaderId: "userA",
            policy: .premium,
            step: .detail
        )

        // Assert

        let expectedOperations: [Operation] = [
            .upload(storagePath: Self.uploadedImage.storagePath, data: Self.upload.data),
            .insertItems(
                [.makeForTest(id: 1, indexedDate: Self.now, createdAt: Self.now, images: [Self.uploadedImage])],
                cohabitantId: Self.cohabitantId
            ),
        ]
        #expect(await operations.values == expectedOperations)
    }

    @Test("参照の書き込みに失敗すると、上げた実体を消し、Analyticsに失敗を送ってエラーを返す")
    func addImages_referenceWriteFailure_deletesUploadedFile() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now)
        let store = HouseworkListStore(
            houseworkClient: .init(addImagesHandler: { _, _, _ in throw WriteError() }),
            houseworkImageClient: Self.makeImageClient(operations),
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            items: [.makeForTest(items: [item])]
        )

        // Act

        await #expect(throws: WriteError.self) {
            try await store.addImages(
                [Self.upload],
                target: item,
                cohabitantId: Self.cohabitantId,
                isRegistered: true,
                uploaderId: "userA",
                policy: .premium,
                step: .detail
            )
        }

        // Assert

        let expectedOperations: [Operation] = [
            .upload(storagePath: Self.uploadedImage.storagePath, data: Self.upload.data),
            .deleteFile(storagePath: Self.uploadedImage.storagePath),
        ]
        #expect(await operations.values == expectedOperations)
        #expect(logger.value == [.housework(.addImage(step: .detail, isSuccess: false))])
    }

    @Test("実体を上げるのに失敗すると、参照を書かずに、上げようとした実体を消してエラーを返す")
    func addImages_uploadFailure_doesNotWriteReference() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now)
        let store = HouseworkListStore(
            houseworkClient: .init(
                createItemsHandler: { _, _ in Issue.record() },
                addImagesHandler: { _, _, _ in Issue.record() }
            ),
            houseworkImageClient: Self.makeImageClient(operations, uploadError: WriteError()),
            items: [.makeForTest(items: [item])]
        )

        // Act

        await #expect(throws: WriteError.self) {
            try await store.addImages(
                [Self.upload],
                target: item,
                cohabitantId: Self.cohabitantId,
                isRegistered: true,
                uploaderId: "userA",
                policy: .premium,
                step: .detail
            )
        }

        // Assert

        #expect(await operations.values == [.deleteFile(storagePath: Self.uploadedImage.storagePath)])
    }

    @Test(
        "無料プラン、または同居人が完了にしていた家事には、何も上げずにエラーを返す",
        arguments: [
            (HouseworkImagePolicy.free, HouseworkState.incomplete, HouseworkImageError.premiumRequired),
            (.premium, .completed, .notEditable),
        ]
    )
    func addImages_notAllowed_doesNotUpload(
        policy: HouseworkImagePolicy,
        latestState: HouseworkState,
        expected: HouseworkImageError
    ) async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now)
        let store = HouseworkListStore(
            houseworkClient: .init(
                createItemsHandler: { _, _ in Issue.record() },
                addImagesHandler: { _, _, _ in Issue.record() }
            ),
            houseworkImageClient: Self.makeImageClient(operations),
            // 画面を開いている間に同居人が状態を変えた、最新の記録
            items: [.makeForTest(items: [.makeForTest(id: 1, indexedDate: Self.now, state: latestState)])]
        )

        // Act

        await #expect(throws: expected) {
            try await store.addImages(
                [Self.upload],
                target: item,
                cohabitantId: Self.cohabitantId,
                isRegistered: true,
                uploaderId: "userA",
                policy: policy,
                step: .detail
            )
        }

        // Assert

        #expect(await operations.values == [])
    }

}

// MARK: - 削除

extension HouseworkListStoreImageTest {

    @Test("画像を消すと、参照を取り除いてから実体を消す")
    func removeImage_removesReferenceThenFile() async throws {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let item = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: Self.now,
            state: .completed,
            images: [Self.othersImage]
        )
        let store = HouseworkListStore(
            houseworkClient: .init(removeImageHandler: { houseworkId, image, cohabitantId in
                await operations.append(
                    .removeReference(houseworkId: houseworkId, image: image, cohabitantId: cohabitantId)
                )
            }),
            houseworkImageClient: Self.makeImageClient(operations),
            cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            items: [.makeForTest(items: [item])]
        )

        // Act

        try await store.removeImage(
            "image0",
            target: item,
            cohabitantId: Self.cohabitantId,
            userId: "userA",
            policy: .premium,
            step: .detail
        )

        // Assert

        let expectedOperations: [Operation] = [
            .removeReference(houseworkId: "id1", image: Self.othersImage, cohabitantId: Self.cohabitantId),
            .deleteFile(storagePath: Self.othersImage.storagePath),
        ]
        #expect(await operations.values == expectedOperations)
        #expect(logger.value == [.housework(.removeImage(step: .detail, isSuccess: true))])
    }

    @Test("無料プランで同居人が追加した画像を消そうとすると、何も書き込まずにエラーを返す")
    func removeImage_notDeletable_doesNotWrite() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now, images: [Self.othersImage])
        let store = HouseworkListStore(
            houseworkClient: .init(removeImageHandler: { _, _, _ in Issue.record() }),
            houseworkImageClient: Self.makeImageClient(operations),
            items: [.makeForTest(items: [item])]
        )

        // Act

        await #expect(throws: HouseworkImageError.notDeletable) {
            try await store.removeImage(
                "image0",
                target: item,
                cohabitantId: Self.cohabitantId,
                userId: "userA",
                policy: .free,
                step: .detail
            )
        }

        // Assert

        #expect(await operations.values == [])
    }

    @Test("同居人が先に消していた画像を消そうとしたときは、何もしない")
    func removeImage_alreadyRemoved_doesNothing() async throws {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let item = HouseworkItem.makeForTest(id: 1, indexedDate: Self.now, images: [Self.othersImage])
        let store = HouseworkListStore(
            houseworkClient: .init(removeImageHandler: { _, _, _ in Issue.record() }),
            houseworkImageClient: Self.makeImageClient(operations),
            analyticsClient: .init(log: { _ in Issue.record() }),
            items: [.makeForTest(items: [.makeForTest(id: 1, indexedDate: Self.now, images: [])])]
        )

        // Act

        try await store.removeImage(
            "image0",
            target: item,
            cohabitantId: Self.cohabitantId,
            userId: "userA",
            policy: .premium,
            step: .detail
        )

        // Assert

        #expect(await operations.values == [])
    }

}

// MARK: - 登録と一緒に添える

extension HouseworkListStoreImageTest {

    @Test("画像を添えて家事を登録すると、実体を上げてから参照を付けた家事を書き込む")
    func register_withImages_uploadsThenInsertsItems() async throws {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(createItemsHandler: { items, cohabitantId in
                await operations.append(.insertItems(items, cohabitantId: cohabitantId))
            }),
            houseworkImageClient: Self.makeImageClient(operations),
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            now: { Self.now }
        )

        // Act

        try await store.register(
            newItems: [
                .init(item: .makeForTest(id: 1, indexedDate: Self.now), source: .manual, images: [Self.upload]),
                .init(item: .makeForTest(id: 2, indexedDate: Self.now), source: .frequent),
            ],
            cohabitantId: Self.cohabitantId,
            step: .board,
            memoLimitPolicy: .free,
            imagePolicy: .premium,
            uploaderId: "userA"
        )

        // Assert

        let expectedOperations: [Operation] = [
            .upload(storagePath: Self.uploadedImage.storagePath, data: Self.upload.data),
            .insertItems(
                [
                    .makeForTest(id: 1, indexedDate: Self.now, createdAt: Self.now, images: [Self.uploadedImage]),
                    .makeForTest(id: 2, indexedDate: Self.now, createdAt: Self.now),
                ],
                cohabitantId: Self.cohabitantId
            ),
        ]
        #expect(await operations.values == expectedOperations)
        let expectedEvents: [AnalyticsEvent] = [
            .housework(.register(step: .board, source: .manual, isSuccess: true)),
            .housework(.register(step: .board, source: .frequent, isSuccess: true)),
            .housework(.addImage(step: .board, isSuccess: true)),
        ]
        #expect(logger.value == expectedEvents)
    }

    @Test("画像を添えた家事の書き込みに失敗すると、上げた実体を消してエラーを返す")
    func register_writeFailure_deletesUploadedFiles() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let store = HouseworkListStore(
            houseworkClient: .init(createItemsHandler: { _, _ in throw WriteError() }),
            houseworkImageClient: Self.makeImageClient(operations)
        )

        // Act

        await #expect(throws: WriteError.self) {
            try await store.register(
                newItems: [
                    .init(item: .makeForTest(id: 1, indexedDate: Self.now), source: .manual, images: [Self.upload]),
                ],
                cohabitantId: Self.cohabitantId,
                step: .board,
                memoLimitPolicy: .free,
                imagePolicy: .premium,
                uploaderId: "userA"
            )
        }

        // Assert

        let expectedOperations: [Operation] = [
            .upload(storagePath: Self.uploadedImage.storagePath, data: Self.upload.data),
            .deleteFile(storagePath: Self.uploadedImage.storagePath),
        ]
        #expect(await operations.values == expectedOperations)
    }

    @Test("無料プランで画像を添えた家事を登録しようとすると、何も上げず・書き込まずにエラーを返す")
    func register_freeWithImages_doesNotWrite() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let store = HouseworkListStore(
            houseworkClient: .init(createItemsHandler: { _, _ in Issue.record() }),
            houseworkImageClient: Self.makeImageClient(operations)
        )

        // Act

        await #expect(throws: HouseworkImageError.premiumRequired) {
            try await store.register(
                newItems: [
                    .init(item: .makeForTest(id: 1, indexedDate: Self.now), source: .manual, images: [Self.upload]),
                ],
                cohabitantId: Self.cohabitantId,
                step: .board,
                memoLimitPolicy: .free,
                imagePolicy: .free,
                uploaderId: "userA"
            )
        }

        // Assert

        #expect(await operations.values == [])
    }

    @Test("メモが上限を超えた家事があると、画像を上げずにエラーを返す")
    func register_memoOverLimit_doesNotUpload() async {
        // Arrange

        let operations = TestLockedArray<Operation>()
        let store = HouseworkListStore(
            houseworkClient: .init(createItemsHandler: { _, _ in Issue.record() }),
            houseworkImageClient: Self.makeImageClient(operations)
        )
        let overLimitMemo = HouseworkMemo(
            text: String(repeating: "あ", count: HouseworkMemoLimitPolicy.freeMaxCharacterCount + 1),
            checklist: []
        )

        // Act

        await #expect(throws: HouseworkMemoError.limitExceeded) {
            try await store.register(
                newItems: [
                    .init(
                        item: .makeForTest(id: 1, indexedDate: Self.now, memo: overLimitMemo),
                        source: .manual,
                        images: [Self.upload]
                    ),
                ],
                cohabitantId: Self.cohabitantId,
                step: .board,
                memoLimitPolicy: .free,
                imagePolicy: .premium,
                uploaderId: "userA"
            )
        }

        // Assert

        #expect(await operations.values == [])
    }

}
