//
//  EncouragementCommentClient.swift
//  LocalPackage
//

import Foundation

/// ねぎらいのコメントをFoundation Modelsで生成するClient（ADR-0042）
public struct EncouragementCommentClient: Sendable {

    /// 実施状況から、ねぎらいのコメントを生成する
    /// - Throws: Foundation Modelsを使えない端末・生成エラー・タイムアウト。呼び出し側は固定文言にフォールバックする
    public let generate: @Sendable (EncouragementContext) async throws -> String

    public init(generate: (@Sendable (EncouragementContext) async throws -> String)? = nil) {
        // デフォルト引数にasyncクロージャを書くと、Xcode 26でビルドしたテストの並列実行で落ちるため、init本体で埋める
        self.generate = generate ?? { _ in throw EncouragementCommentError.unavailable }
    }

}

public extension EncouragementCommentClient {

    static let previewValue: EncouragementCommentClient = .init { _ in
        "今日も洗い物と洗濯、おつかれさまです。3日続けて家事をしていて、すてきですね"
    }

}

/// コメントを生成できなかった理由
public enum EncouragementCommentError: Error, Equatable {

    /// 非対応端末・Apple Intelligenceがオフ・モデルの準備中・言語非対応などで、モデルを使えない
    case unavailable
    /// 決めた時間内に生成が終わらなかった
    case timeout

}
