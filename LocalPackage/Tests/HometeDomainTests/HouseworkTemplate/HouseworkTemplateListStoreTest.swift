//
//  HouseworkTemplateListStoreTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/09.
//

@testable import HometeDomain
import Testing

@MainActor
struct HouseworkTemplateListStoreTest {

    private let inputCohabitantId = "cohabitantId"

    @Test("テンプレート一覧の取得を行うと、Clientから受け取ったテンプレート一覧をtemplatesに反映する")
    func loadTemplates() async throws {
        // Arrange

        let expectedTemplates: [HouseworkTemplateMeta] = [
            .init(templateId: "template1", name: "平日テンプレ", version: 0),
            .init(templateId: "template2", name: "週末テンプレ", version: 3),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchTemplates: { cohabitantId in
                    #expect(cohabitantId == inputCohabitantId)
                    return expectedTemplates
                }
            )
        )

        // Act

        try await store.loadTemplates(cohabitantId: inputCohabitantId)

        // Assert

        #expect(store.templates == expectedTemplates)
    }

    @Test("曜日定義の取得を行うと、Clientから受け取った定義をselectedDaysに反映する")
    func loadDays() async throws {
        // Arrange

        let inputTemplateId = "templateId"
        let expectedDays: [HouseworkTemplateDay] = [
            .init(
                dayOfWeek: 1,
                items: [.init(id: .init(id: "id"), title: "ゴミ出し", point: 10, updatedAt: .now)]
            ),
        ]
        let store = HouseworkTemplateListStore(
            houseworkTemplateClient: .init(
                fetchDays: { cohabitantId, templateId in
                    #expect(cohabitantId == inputCohabitantId)
                    #expect(templateId == inputTemplateId)
                    return expectedDays
                }
            )
        )

        // Act

        try await store.loadDays(templateId: inputTemplateId, cohabitantId: inputCohabitantId)

        // Assert

        #expect(store.selectedDays == expectedDays)
    }

    @Test("テンプレートを新規作成すると、version=0で作成しtemplatesにも追加する")
    func createTemplate() async throws {
        // Arrange

        let inputTemplateId = "newTemplateId"
        let inputName = "新しいテンプレ"
        let expectedMeta = HouseworkTemplateMeta(
            templateId: inputTemplateId,
            name: inputName,
            version: 0
        )

        try await confirmation { confirmation in
            let store = HouseworkTemplateListStore(
                houseworkTemplateClient: .init(
                    upsertTemplate: { meta, cohabitantId in
                        // Assert

                        #expect(meta == expectedMeta)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                )
            )

            // Act

            try await store.createTemplate(
                templateId: inputTemplateId,
                name: inputName,
                cohabitantId: inputCohabitantId
            )

            // Assert

            #expect(store.templates == [expectedMeta])
        }
    }

}
