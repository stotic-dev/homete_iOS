//
//  EncouragementComment.swift
//  LocalPackage
//

import Foundation

/// ダッシュボードに出す、ねぎらいのコメント
///
/// - Note: 文言はLLMの生成結果そのものが表示内容になるため、固定文言も含めてドメイン側で持つ
///         （Push通知の本文と同じ扱い）。どの文言でも禁止表現を含まないことをユニットテストで担保する。
public struct EncouragementComment: Equatable, Sendable, Codable {

    public let text: String
    public let kind: Kind
    public let source: Source

    public init(text: String, kind: Kind, source: Source) {
        self.text = text
        self.kind = kind
        self.source = source
    }

}

public extension EncouragementComment {

    /// コメントの種類
    enum Kind: String, Equatable, Sendable, Codable {

        /// 自分の実績がまだない日の、中立・励ましのコメント
        case neutral
        /// 自分の実績をねぎらうコメント
        case selfPraise

    }

    /// 文言の出どころ
    enum Source: String, Equatable, Sendable, Codable {

        /// Foundation Modelsで生成した
        case generated
        /// あらかじめ用意した固定文言
        case fixed

    }

}

/// コメントを作り直す節目
///
/// 生成は節目ごとに1回だけ行い、同じ節目の間はキャッシュを出し続ける。
public enum EncouragementMilestone: String, Equatable, Sendable, Codable {

    /// 自分の当日の完了が0件。生成せず、中立の固定文言を出す
    case noActivity
    /// 自分の完了が1件以上で、今日の家事に未完了がある
    case inProgress
    /// 自分の完了が1件以上で、今日の家事が全て完了した
    case allCompleted

    public init(context: EncouragementContext) {
        if context.own.todayCompletedCount == 0 {
            self = .noActivity
        } else if context.today.isAllCompleted {
            self = .allCompleted
        } else {
            self = .inProgress
        }
    }

}
