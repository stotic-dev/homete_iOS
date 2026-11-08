//
//  HouseworkImage.swift
//  LocalPackage
//

/// 家事に添えた画像の参照
///
/// 画像の実体はFirebase Storageに置き、家事のドキュメントには保存先だけを持たせる（ADR-0067）。
/// 保存先は同居人グループ・家事ごとのフォルダにし、家事が消えたときにフォルダごと消せるようにする。
public struct HouseworkImage: Identifiable, Codable, Sendable, Equatable, Hashable {

    public let id: String
    /// Storageでの保存先
    public let storagePath: String
    /// 追加した人のユーザーID。プレミアムプランをやめた後も、自分が追加した画像は消せるようにするために使う
    public let uploaderId: String

    public init(id: String, storagePath: String, uploaderId: String) {
        self.id = id
        self.storagePath = storagePath
        self.uploaderId = uploaderId
    }

    /// 家事に新しく添える画像の参照を作る
    /// - Parameters:
    ///   - id: 画像ID。保存先のファイル名にもなる
    ///   - houseworkId: 添える家事のID
    ///   - cohabitantId: 家事の同居人グループのID
    ///   - uploaderId: 追加した人のユーザーID
    public static func make(id: String, houseworkId: String, cohabitantId: String, uploaderId: String) -> Self {
        .init(
            id: id,
            storagePath: "Cohabitant/\(cohabitantId)/Houseworks/\(houseworkId)/\(id).jpg",
            uploaderId: uploaderId
        )
    }

}

public extension [HouseworkImage]? {

    // swiftlint:disable:this discouraged_optional_collection

    /// 表示する画像があるか。一度も添えていない（`nil`）か、添えた画像をすべて消した（空）なら`false`
    var hasContent: Bool {
        guard let self else { return false }
        return !self.isEmpty
    }

}
