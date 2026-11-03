//
//  StorageService.swift
//

import FirebaseStorage
import Foundation

/// Firebase Storageへの読み書き
///
/// 家事に添えた画像の実体を置く（ADR-0067）。参照はFirestoreの家事のドキュメントが持つ。
public enum StorageService {

    /// 取得する画像の最大バイト数。上げる画像の上限（2MB）より少し大きくしておく
    private static let maxDownloadByteCount: Int64 = 3 * 1024 * 1024

    /// JPEGを上げる
    public static func uploadJPEG(_ data: Data, path: String) async throws {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await Storage.storage().reference(withPath: path).putDataAsync(data, metadata: metadata)
    }

    /// ファイルを消す。すでに無い場合も成功として扱う
    /// - Note: 参照を消した後の後片付けで呼ぶため、同居人が先に消していても失敗にしない
    public static func delete(path: String) async throws {
        do {
            try await Storage.storage().reference(withPath: path).delete()
        } catch let error as NSError
            where error.domain == StorageErrorDomain && error.code == StorageErrorCode.objectNotFound.rawValue {
            return
        }
    }

    /// ファイルを取得する
    public static func data(path: String) async throws -> Data {
        try await Storage.storage().reference(withPath: path).data(maxSize: maxDownloadByteCount)
    }

}
