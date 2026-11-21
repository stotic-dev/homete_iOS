//
//  HouseworkImageUpload.swift
//  LocalPackage
//

import Foundation

/// これから家事に添える画像（まだ上げていないもの）
public struct HouseworkImageUpload: Identifiable, Equatable, Sendable {

    /// 画像ID。上げるときの保存先のファイル名にもなる
    public let id: String
    /// `HouseworkImageProcessor.makeUploadData(from:)`で縮小・圧縮したJPEG
    public let data: Data

    public init(id: String, data: Data) {
        self.id = id
        self.data = data
    }

}
