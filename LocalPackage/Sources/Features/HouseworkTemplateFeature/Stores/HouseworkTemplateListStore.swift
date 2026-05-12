//
//  HouseworkTemplateListStore.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import HometeDomain
import Observation

@MainActor
@Observable
final class HouseworkTemplateListStore {

    private(set) var templates: [HouseworkTemplateMeta]
    private(set) var selectedDays: [HouseworkTemplateDay]

    private let houseworkTemplateClient: HouseworkTemplateClient

    public init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        templates: [HouseworkTemplateMeta] = [],
        selectedDays: [HouseworkTemplateDay] = []
    ) {

        self.houseworkTemplateClient = houseworkTemplateClient
        self.templates = templates
        self.selectedDays = selectedDays
    }

    /// テンプレート一覧をワンショット取得する
    func loadTemplates(cohabitantId: String) async throws {

        templates = try await houseworkTemplateClient.fetchTemplates(cohabitantId)
    }

    /// 指定テンプレートの曜日別定義をワンショット取得する
    func loadDays(templateId: String, cohabitantId: String) async throws {

        selectedDays = try await houseworkTemplateClient.fetchDays(cohabitantId, templateId)
    }

    /// 新規テンプレートを作成する
    func createTemplate(
        templateId: String,
        name: String,
        cohabitantId: String
    ) async throws {

        let newMeta = HouseworkTemplateMeta(
            templateId: templateId,
            name: name,
            version: 0
        )
        try await houseworkTemplateClient.upsertTemplate(newMeta, cohabitantId)
        templates.append(newMeta)
    }
}
