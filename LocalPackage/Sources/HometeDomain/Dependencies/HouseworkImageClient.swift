//
//  HouseworkImageClient.swift
//  LocalPackage
//

import Foundation

/// 家事に添えた画像の実体を、保存先（Firebase Storage）に読み書きするClient
/// - Note: 家事のドキュメントに持たせる参照（`HouseworkItem.images`）は`HouseworkClient`で書く（ADR-0067）
public struct HouseworkImageClient: Sendable {

    /// 縮小・圧縮したJPEGを保存先に上げる
    public let upload: @Sendable (_ data: Data, _ storagePath: String) async throws -> Void
    /// 画像を消す。すでに無い場合も成功として扱う
    public let delete: @Sendable (_ storagePath: String) async throws -> Void
    /// 画像を取得する
    /// - Note: 同じ保存先の画像は内容が変わらないため、一度取得した画像は端末に残し、2回目からは通信しない
    public let fetch: @Sendable (_ storagePath: String) async throws -> Data
    /// 端末に残した画像をすべて消す。ログアウト・退会したときに、前のアカウントの写真を端末に残さないため
    public let clearCache: @Sendable () async -> Void

    public init(
        upload: (@Sendable (_ data: Data, _ storagePath: String) async throws -> Void)? = nil,
        delete: (@Sendable (_ storagePath: String) async throws -> Void)? = nil,
        fetch: (@Sendable (_ storagePath: String) async throws -> Data)? = nil,
        clearCache: (@Sendable () async -> Void)? = nil
    ) {
        // デフォルト引数にクロージャを書くと、Xcode 26系（Swift 6.2〜6.3）のビルドで並列に呼ばれたときに
        // asyncフレームが壊れてクラッシュする。そのためデフォルト値はnilにして、既定の実装は本体で代入する
        self.upload = upload ?? { _, _ in }
        self.delete = delete ?? { _ in }
        self.fetch = fetch ?? { _ in throw HouseworkImageError.unreadable }
        self.clearCache = clearCache ?? {}
    }

}

public extension HouseworkImageClient {

    static let previewValue: HouseworkImageClient = .init()

}
