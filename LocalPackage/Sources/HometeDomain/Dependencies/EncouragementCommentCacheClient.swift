//
//  EncouragementCommentCacheClient.swift
//  LocalPackage
//

import Foundation

/// その日のねぎらいのコメントを端末に保存するClient
///
/// 生成は節目ごとに1回だけ行うため、アプリを起動し直しても同じ節目の間は保存したコメントを出す。
public struct EncouragementCommentCacheClient: Sendable {

    /// 保存したコメントを読み出す。保存していなければ`nil`
    public let load: @Sendable () async -> EncouragementCommentCache?
    /// コメントを保存する（前に保存したものは上書きする）
    public let save: @Sendable (EncouragementCommentCache) async -> Void

    public init(
        load: (@Sendable () async -> EncouragementCommentCache?)? = nil,
        save: (@Sendable (EncouragementCommentCache) async -> Void)? = nil
    ) {
        // デフォルト引数にasyncクロージャを書くと、Xcode 26でビルドしたテストの並列実行で落ちるため、init本体で埋める
        self.load = load ?? { nil }
        self.save = save ?? { _ in }
    }

}

public extension EncouragementCommentCacheClient {

    static let previewValue: EncouragementCommentCacheClient = .init()

}

/// 保存したコメントと、それがいつ・誰の・どの節目のものか
public struct EncouragementCommentCache: Equatable, Sendable, Codable {

    public let userId: String
    /// コメントを作った日（その日の0時）
    public let day: Date
    public let milestone: EncouragementMilestone
    public let comment: EncouragementComment

    public init(userId: String, day: Date, milestone: EncouragementMilestone, comment: EncouragementComment) {
        self.userId = userId
        self.day = day
        self.milestone = milestone
        self.comment = comment
    }

}
