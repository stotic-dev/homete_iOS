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

    /// 毎月の家事の取得（ワンショット）
    /// - Note: 解釈できないドキュメント（新しい種類の繰り返しルールなど）は除外して返す
    public let fetchMonthlyItems: @Sendable (
        _ cohabitantId: String,
        _ templateId: String
    ) async throws -> [HouseworkTemplateMonthlyItem]

    /// 曜日定義と毎月の家事の一括更新（楽観的ロック付きトランザクション）
    public let updateTemplate: @Sendable (
        _ update: HouseworkTemplateUpdate,
        _ templateId: String,
        _ cohabitantId: String,
        _ currentVersion: Int
    ) async throws -> Void

    /// テンプレートへの家事の追加（家事登録画面用）
    /// - Note: トランザクション内で最新の内容を読んで追記し、versionを上げる。
    ///         編集中の他メンバーの保存はversionの不一致でコンフリクトとして検知される
    public let appendItem: @Sendable (
        _ item: HouseworkTemplateItem,
        _ recurrence: HouseworkRecurrence,
        _ templateId: String,
        _ cohabitantId: String
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

    /// MonthlyItems の SnapshotListener
    public let addMonthlyItemsSnapshotListener: @Sendable (
        _ id: String,
        _ templateId: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[HouseworkTemplateMonthlyItem]>

    /// Tesmplates の SnapshotListener
    public let addTemplatesSnapshotListener: @Sendable (
        _ id: String,
        _ cohabitantId: String
    ) async -> AsyncStream<[HouseworkTemplateMeta]>

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
        fetchTemplates: (@Sendable (
            _ cohabitantId: String
        ) async throws -> [HouseworkTemplateMeta])? = nil,
        fetchDays: (@Sendable (
            _ cohabitantId: String,
            _ templateId: String
        ) async throws -> [HouseworkTemplateDay])? = nil,
        upsertTemplate: (@Sendable (
            _ meta: HouseworkTemplateMeta,
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        fetchMonthlyItems: (@Sendable (
            _ cohabitantId: String,
            _ templateId: String
        ) async throws -> [HouseworkTemplateMonthlyItem])? = nil,
        updateTemplate: (@Sendable (
            _ update: HouseworkTemplateUpdate,
            _ templateId: String,
            _ cohabitantId: String,
            _ currentVersion: Int
        ) async throws -> Void)? = nil,
        appendItem: (@Sendable (
            _ item: HouseworkTemplateItem,
            _ recurrence: HouseworkRecurrence,
            _ templateId: String,
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        upsertEditor: (@Sendable (
            _ editor: HouseworkTemplateEditor,
            _ templateId: String,
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        removeEditor: (@Sendable (
            _ userId: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async throws -> Void)? = nil,
        addDaysSnapshotListener: (@Sendable (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateDay]>)? = nil,
        addMonthlyItemsSnapshotListener: (@Sendable (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateMonthlyItem]>)? = nil,
        addTemplatesSnapshotListener: (@Sendable (
            _ id: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateMeta]>)? = nil,
        addEditorsSnapshotListener: (@Sendable (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<[HouseworkTemplateEditor]>)? = nil,
        addMetaVersionSnapshotListener: (@Sendable (
            _ id: String,
            _ templateId: String,
            _ cohabitantId: String
        ) async -> AsyncStream<Int>)? = nil,
        removeListener: (@Sendable (_ id: String) async -> Void)? = nil
    ) {
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュする。そのためデフォルト値はnilにして、既定の実装は本体で代入する
        self.fetchTemplates = fetchTemplates ?? { _ in [] }
        self.fetchDays = fetchDays ?? { _, _ in [] }
        self.upsertTemplate = upsertTemplate ?? { _, _ in }
        self.fetchMonthlyItems = fetchMonthlyItems ?? { _, _ in [] }
        self.updateTemplate = updateTemplate ?? { _, _, _, _ in }
        self.appendItem = appendItem ?? { _, _, _, _ in }
        self.upsertEditor = upsertEditor ?? { _, _, _ in }
        self.removeEditor = removeEditor ?? { _, _, _ in }
        self.addDaysSnapshotListener = addDaysSnapshotListener ?? { _, _, _ in .makeStream().stream }
        self.addMonthlyItemsSnapshotListener = addMonthlyItemsSnapshotListener ?? { _, _, _ in .makeStream().stream }
        self.addTemplatesSnapshotListener = addTemplatesSnapshotListener ?? { _, _ in .makeStream().stream }
        self.addEditorsSnapshotListener = addEditorsSnapshotListener ?? { _, _, _ in .makeStream().stream }
        self.addMetaVersionSnapshotListener = addMetaVersionSnapshotListener ?? { _, _, _ in .makeStream().stream }
        self.removeListener = removeListener ?? { _ in }
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
