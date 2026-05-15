public struct HouseworkTemplateClient: Sendable {

    /// テンプレート一覧取得（ワンショット）
    public let fetchTemplates: @Sendable (_ cohabitantId: String) async throws -> [HouseworkTemplateMeta]

    /// 特定テンプレートの曜日別定義取得（ワンショット）
    public let fetchDays: @Sendable (
        _ cohabitantId: String,
        _ templateId: String
    ) async throws -> [HouseworkTemplateDay]

    /// テンプレートメタの作成・更新
    public let upsertTemplate: @Sendable (
        _ meta: HouseworkTemplateMeta,
        _ cohabitantId: String
    ) async throws -> Void

    /// 曜日定義の更新（楽観的ロック付きトランザクション）
    public let updateDay: @Sendable (
        _ day: HouseworkTemplateDay,
        _ templateId: String,
        _ cohabitantId: String,
        _ currentVersion: Int
    ) async throws -> Void

    /// Editor presence の upsert（編集開始・keepalive）
    public let upsertEditor: @Sendable (
        _ editor: HouseworkTemplateEditor,
        _ templateId: String,
        _ cohabitantId: String
    ) async throws -> Void

    /// Editor presence の削除（編集終了・離脱）
    public let removeEditor: @Sendable (
        _ userId: String,
        _ templateId: String,
        _ cohabitantId: String
    ) async throws -> Void

    /// Days の SnapshotListener（編集中のみ使用）
    public let addDaysSnapshotListener: @Sendable (
        _ id: String,
        _ templateId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[HouseworkTemplateDay]>

    /// Editors の SnapshotListener（編集中のみ使用）
    public let addEditorsSnapshotListener: @Sendable (
        _ id: String,
        _ templateId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[HouseworkTemplateEditor]>

    /// テンプレートメタの version SnapshotListener（編集中のみ使用、楽観的ロックの currentVersion 取得用）
    public let addMetaVersionSnapshotListener: @Sendable (
        _ id: String,
        _ templateId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<Int>

    /// SnapshotListener の解除
    public let removeListener: @Sendable (_ id: String) async -> Void

    public init(
        fetchTemplates: @Sendable @escaping (
            _ cohabitantId: String
        ) async throws -> [HouseworkTemplateMeta] = { _ in [] },
        fetchDays: @Sendable @escaping (
            _ cohabitantId: String,
            _ templateId: String
        ) async throws -> [HouseworkTemplateDay] = { _, _ in [] },
        upsertTemplate: @Sendable @escaping (
            _ meta: HouseworkTemplateMeta,
            _ cohabitantId: String
        ) async throws -> Void = { _, _ in },
        updateDay: @Sendable @escaping (
            _ day: HouseworkTemplateDay,
            _ templateId: String,
            _ cohabitantId: String,
            _ currentVersion: Int
        ) async throws -> Void = { _, _, _, _ in },
        upsertEditor: @Sendable @escaping (
            _ editor: HouseworkTemplateEditor,
            _ templateId: String,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _ in },
        removeEditor: @Sendable @escaping (
            _ userId: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async throws -> Void = { _, _, _ in },
        addDaysSnapshotListener: @Sendable @escaping (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateDay]> = { _, _, _ in .makeStream().stream },
        addEditorsSnapshotListener: @Sendable @escaping (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateEditor]> = { _, _, _ in .makeStream().stream },
        addMetaVersionSnapshotListener: @Sendable @escaping (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<Int> = { _, _, _ in .makeStream().stream },
        removeListener: @Sendable @escaping (_ id: String) async -> Void = { _ in }
    ) {
        self.fetchTemplates = fetchTemplates
        self.fetchDays = fetchDays
        self.upsertTemplate = upsertTemplate
        self.updateDay = updateDay
        self.upsertEditor = upsertEditor
        self.removeEditor = removeEditor
        self.addDaysSnapshotListener = addDaysSnapshotListener
        self.addEditorsSnapshotListener = addEditorsSnapshotListener
        self.addMetaVersionSnapshotListener = addMetaVersionSnapshotListener
        self.removeListener = removeListener
    }

}

public extension HouseworkTemplateClient {

    static let previewValue: HouseworkTemplateClient = .init()

}

/// Firestore 上のテンプレートメタドキュメントを表現する内部構造体。
/// `version` は Infrastructure 層でのみ扱い、Domain には公開しない。
public struct HouseworkTemplateMetaDocument: Codable, Sendable {

    public let templateId: String
    public let name: String
    public let version: Int

    public init(templateId: String, name: String, version: Int) {
        self.templateId = templateId
        self.name = name
        self.version = version
    }

}
