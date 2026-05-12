//
//  HouseworkTemplateEditStore.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import Foundation
import HometeDomain
import Observation

@MainActor
@Observable
final class HouseworkTemplateEditStore {

    private(set) var days: [HouseworkTemplateDay]
    private(set) var editors: [HouseworkTemplateEditor]
    private(set) var currentVersion: Int

    private var daysObserveTask: Task<Void, Never>?
    private var editorsObserveTask: Task<Void, Never>?
    private var keepaliveTask: Task<Void, Never>?

    private let houseworkTemplateClient: HouseworkTemplateClient

    private let daysListenerKey = "houseworkTemplateDaysListener"
    private let editorsListenerKey = "houseworkTemplateEditorsListener"
    
    // Editor ドキュメントの TTL（5分）
    private static let editorTTL: TimeInterval = 5 * 60

    public init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        days: [HouseworkTemplateDay] = [],
        editors: [HouseworkTemplateEditor] = [],
        currentVersion: Int = 0
    ) {

        self.houseworkTemplateClient = houseworkTemplateClient
        self.days = days
        self.editors = editors
        self.currentVersion = currentVersion
    }

    /// 編集モードを開始する。Days と Editors の SnapshotListener を張り、自身を Editor として登録する
    /// - Parameters:
    ///   - meta: 編集対象のテンプレートメタ（version の初期値として使う）
    ///   - cohabitantId: 同居人ID
    ///   - userId: 編集中ユーザーID
    ///   - now: 現在時刻
    ///   - keepaliveInterval: Editor の updatedAt を再upsertする周期（nil で無効化、デフォルト1分）
    func startEditing(
        meta: HouseworkTemplateMeta,
        cohabitantId: String,
        userId: String,
        now: Date,
        keepaliveInterval: TimeInterval = 60
    ) async throws {

        currentVersion = meta.version

        let editor = HouseworkTemplateEditor(
            userId: userId,
            updatedAt: now,
            expiredAt: now.addingTimeInterval(Self.editorTTL)
        )
        try await houseworkTemplateClient.upsertEditor(editor, meta.templateId, cohabitantId)

        let daysStream = await houseworkTemplateClient.addDaysSnapshotListener(
            daysListenerKey,
            meta.templateId,
            cohabitantId
        )
        daysObserveTask = Task {

            for await currentDays in daysStream {

                self.days = currentDays
            }
        }

        let editorsStream = await houseworkTemplateClient.addEditorsSnapshotListener(
            editorsListenerKey,
            meta.templateId,
            cohabitantId
        )
        editorsObserveTask = Task {

            for await currentEditors in editorsStream {

                self.editors = currentEditors
            }
        }

        startKeepalive(
            templateId: meta.templateId,
            cohabitantId: cohabitantId,
            userId: userId,
            editorTTL: Self.editorTTL,
            keepaliveInterval: keepaliveInterval
        )
    }

    /// 編集モードを終了する。SnapshotListener を解除し、自身の Editor を削除する
    func stopEditing(
        templateId: String,
        cohabitantId: String,
        userId: String
    ) async {

        daysObserveTask?.cancel()
        editorsObserveTask?.cancel()
        keepaliveTask?.cancel()
        daysObserveTask = nil
        editorsObserveTask = nil
        keepaliveTask = nil

        await houseworkTemplateClient.removeListener(daysListenerKey)
        await houseworkTemplateClient.removeListener(editorsListenerKey)

        try? await houseworkTemplateClient.removeEditor(userId, templateId, cohabitantId)
    }

    /// 曜日定義を保存する。version の楽観的ロックで競合が発生した場合は HouseworkTemplateError.versionConflict を throw する。
    /// 保存成功後の `days` プロパティの更新は Days SnapshotListener による反映に委ねる（ローカルでは更新しない）
    func saveDay(
        _ day: HouseworkTemplateDay,
        templateId: String,
        cohabitantId: String
    ) async throws {

        try await houseworkTemplateClient.updateDay(
            day,
            templateId,
            cohabitantId,
            currentVersion
        )
        currentVersion += 1
    }
}

private extension HouseworkTemplateEditStore {

    func startKeepalive(
        templateId: String,
        cohabitantId: String,
        userId: String,
        editorTTL: TimeInterval,
        keepaliveInterval: TimeInterval
    ) {

        keepaliveTask = Task {

            while !Task.isCancelled {

                try? await Task.sleep(for: .seconds(keepaliveInterval))
                guard !Task.isCancelled else { break }
                
                let updatedAt = Date()
                let updated = HouseworkTemplateEditor(
                    userId: userId,
                    updatedAt: updatedAt,
                    expiredAt: updatedAt.addingTimeInterval(editorTTL)
                )
                do {

                    try await houseworkTemplateClient.upsertEditor(
                        updated,
                        templateId,
                        cohabitantId
                    )
                } catch {

                    print("keepalive upsertEditor failed: \(error)")
                }
            }
        }
    }
}
