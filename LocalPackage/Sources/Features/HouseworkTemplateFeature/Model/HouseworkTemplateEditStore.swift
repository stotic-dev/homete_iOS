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

    private(set) var editors: [HouseworkTemplateEditor]
    private(set) var currentVersion: Int
    /// 編集者・バージョンの購読状態
    private(set) var loadState: ListenerLoadState = .loading

    private var editorsObserveTask: Task<Void, Never>?
    private var metaVersionObserveTask: Task<Void, Never>?
    private var keepaliveTask: Task<Void, Never>?

    private let houseworkTemplateClient: HouseworkTemplateClient

    private let editorsListenerKey = "houseworkTemplateEditorsListener"
    private let metaVersionListenerKey = "houseworkTemplateMetaVersionListener"

    /// Editor ドキュメントの TTL（5分）
    private static let editorTTL: TimeInterval = 5 * 60

    init(
        houseworkTemplateClient: HouseworkTemplateClient = .previewValue,
        editors: [HouseworkTemplateEditor] = [],
        currentVersion: Int = 0
    ) {
        self.houseworkTemplateClient = houseworkTemplateClient
        self.editors = editors
        self.currentVersion = currentVersion
    }

    /// 編集モードを開始する。Editors・Meta version の SnapshotListener を張り、自身を Editor として登録する
    /// - Parameters:
    ///   - templateId: 編集対象のテンプレートID
    ///   - cohabitantId: 同居人ID
    ///   - userId: 編集中ユーザーID
    ///   - now: 現在時刻
    ///   - keepaliveInterval: Editor の updatedAt を再upsertする周期（nil で無効化、デフォルト1分）
    func startEditing(
        templateId: String,
        cohabitantId: String,
        userId: String,
        now: Date,
        keepaliveInterval: TimeInterval = 60
    ) async throws {
        loadState = .loading
        let editor = HouseworkTemplateEditor(
            userId: userId,
            updatedAt: now,
            expiredAt: now.addingTimeInterval(Self.editorTTL)
        )
        do {
            try await houseworkTemplateClient.upsertEditor(editor, templateId, cohabitantId)
        } catch {
            loadState = .failed(DomainError.make(error) ?? .other)
            throw error
        }

        let editorsStream = await houseworkTemplateClient.addEditorsSnapshotListener(
            editorsListenerKey,
            templateId,
            cohabitantId
        )
        editorsObserveTask = Task {
            for await result in editorsStream {
                switch result {
                case let .success(currentEditors):
                    // 自分以外のユーザーを現在の編集者として保存する
                    self.editors = currentEditors.filter { $0.userId != userId }

                case let .failure(error):
                    self.handleListenerFailure(error, listenerName: "editors")
                }
            }
        }

        let metaVersionStream = await houseworkTemplateClient.addMetaVersionSnapshotListener(
            metaVersionListenerKey,
            templateId,
            cohabitantId
        )
        metaVersionObserveTask = Task {
            for await result in metaVersionStream {
                switch result {
                case let .success(version):
                    self.currentVersion = version

                case let .failure(error):
                    self.handleListenerFailure(error, listenerName: "metaVersion")
                }
            }
        }

        loadState = .loaded
        startKeepalive(
            templateId: templateId,
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
        loadState = .loading
        editorsObserveTask?.cancel()
        metaVersionObserveTask?.cancel()
        keepaliveTask?.cancel()
        editorsObserveTask = nil
        metaVersionObserveTask = nil
        keepaliveTask = nil

        await houseworkTemplateClient.removeListener(editorsListenerKey)
        await houseworkTemplateClient.removeListener(metaVersionListenerKey)

        try? await houseworkTemplateClient.removeEditor(userId, templateId, cohabitantId)
    }

}

private extension HouseworkTemplateEditStore {

    /// リスナーが失敗を通知してきた場合に、編集を続けさせずエラー表示に倒す
    ///
    /// - Note: 編集者バッジと楽観的ロックのバージョンはどちらも購読が前提のため、片方でも失敗したら
    ///         keepaliveも止める。リトライ時は`stopEditing`→`startEditing`でリスナーを張り直す。
    func handleListenerFailure(_ error: DomainError, listenerName: String) {
        print("error occurred at housework template \(listenerName) listener: \(error)")
        keepaliveTask?.cancel()
        keepaliveTask = nil
        loadState = .failed(error)
    }

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
