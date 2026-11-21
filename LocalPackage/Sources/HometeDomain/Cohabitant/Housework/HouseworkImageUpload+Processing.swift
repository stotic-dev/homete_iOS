//
//  HouseworkImageUpload+Processing.swift
//  LocalPackage
//

import Foundation

public extension HouseworkImageUpload {

    /// フォトライブラリ・カメラから受け取った画像を、上げられる大きさに縮小・圧縮する
    ///
    /// 縮小は重いため、呼び出し元のアクター（メインスレッド）の外で行う。元の画像（RAWなどは1枚数十MB）を
    /// 全部メモリに読んでから縮小しないよう、1枚読んでは縮小する。
    /// - Parameters:
    ///   - originals: 受け取った画像を読み込む処理（選んだ順）。読み込めなかった画像は`nil`を返し、飛ばす
    ///   - idGenerator: 画像IDを作る。`nil`ならUUIDを使う
    /// - Throws: 1枚でも画像として読めなければ`HouseworkImageError.unreadable`
    @concurrent
    static func make(
        loading originals: [@Sendable () async -> Data?],
        idGenerator: (@Sendable () -> String)? = nil
    ) async throws -> [Self] {
        // デフォルト引数にクロージャを書くと、Xcode 26系のビルドでクラッシュすることがあるため、本体で既定値を決める
        let idGenerator = idGenerator ?? { UUID().uuidString }
        var uploads: [Self] = []
        for load in originals {
            guard let original = await load() else { continue }
            try uploads.append(.init(id: idGenerator(), data: HouseworkImageProcessor.makeUploadData(from: original)))
        }
        return uploads
    }

}
