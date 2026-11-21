//
//  PendingEntry.swift
//  LocalPackage
//

/// 登録予定リストの1件
/// - Note: ポイントはここでは変えられない（取り消して入力し直す）
public struct PendingEntry: Equatable, Identifiable, Sendable {

    /// どこから来た1件か（取り消しの対象を特定するのに使う）
    public enum Source: Equatable, Sendable {

        /// いつもの家事から選んだ
        case frequent(itemId: String)
        /// 「続けて入力する」で積んだ
        case queued(entryId: String)
        /// 「新しく入力」タブで入力中
        case editing

    }

    public let source: Source
    public let title: String
    public let point: Int
    /// テンプレートに登録する繰り返し方。その日の家事として登録する場合は`nil`
    public let recurrence: HouseworkRecurrence?
    /// 登録に成功したあと、いつもの家事にも保存するか
    public let savesAsFrequent: Bool
    /// いつもの家事に保存するときのカテゴリ
    public let categoryId: String?
    /// 家事に付けるメモ。いつもの家事に保存するときにも持たせる
    public let memo: HouseworkMemo?
    /// 家事に添える画像。その日の家事として登録するときだけ添え、テンプレート・いつもの家事には持たせない
    public let images: [HouseworkImageUpload]

    public init(
        source: Source,
        title: String,
        point: Int,
        recurrence: HouseworkRecurrence?,
        savesAsFrequent: Bool,
        categoryId: String?,
        memo: HouseworkMemo? = nil,
        images: [HouseworkImageUpload] = []
    ) {
        self.source = source
        self.title = title
        self.point = point
        self.recurrence = recurrence
        self.savesAsFrequent = savesAsFrequent
        self.categoryId = categoryId
        self.memo = memo
        self.images = images
    }

    public var id: String {
        switch source {
        case let .frequent(itemId):
            "frequent.\(itemId)"

        case let .queued(entryId):
            "queued.\(entryId)"

        case .editing:
            "editing"
        }
    }

}

public extension PendingEntry {

    init(queued entry: RegisterHouseworkDraft.ManualEntry) {
        self.init(
            source: .queued(entryId: entry.id),
            title: entry.title,
            point: entry.point,
            recurrence: entry.recurrenceInput.recurrence,
            savesAsFrequent: entry.savesAsFrequent,
            categoryId: entry.categoryId,
            memo: entry.memo,
            images: entry.attachedImages
        )
    }

    init(editing entry: RegisterHouseworkDraft.ManualEntry) {
        self.init(
            source: .editing,
            title: FrequentHouseworkContext.normalize(entry.title),
            point: entry.point,
            recurrence: entry.recurrenceInput.recurrence,
            savesAsFrequent: entry.savesAsFrequent,
            categoryId: entry.categoryId,
            memo: entry.memo,
            images: entry.attachedImages
        )
    }

}
