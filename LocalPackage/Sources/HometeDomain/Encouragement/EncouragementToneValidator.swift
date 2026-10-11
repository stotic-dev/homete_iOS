//
//  EncouragementToneValidator.swift
//  LocalPackage
//

import Foundation

/// 生成したコメントが、トーンのガイドラインを守っているかを確かめる
///
/// LLMの出力は完全には制御できないため、instructionsでの指示に加えて、出力を禁止表現リストで検証する。
/// 語句の一致で判定するため言い回しを変えた比較までは防げないが、典型的な責め・比較・指摘の表現を落とす。
public enum EncouragementToneValidator {

    /// コメントとして出せる最大文字数。カードに2〜3行で収まる長さ
    public static let maxLength = 80

    /// 責める・比べる・要求する・未完了を指摘する表現
    static let forbiddenPhrases = [
        // 少なさ・偏りを責める
        "しかしていない", "しかやっていない", "サボ", "怠け", "少な", "足りな", "偏り", "偏って",
        // 比較・順位づけ
        "比べ", "比較", "順位", "ランキング", "一番", "負け", "勝ち", "差が", "割合", "%", "％",
        "より多く", "より少な", "のほうが", "の方が",
        // 要求・評価
        "もっと", "すべき", "するべき", "なさい",
        // 未完了・遅れの指摘
        "未完了", "残って", "終わっていない", "やっていない", "遅れ",
    ]

    /// 出せるコメントに整えて返す。出せない場合は`nil`
    ///
    /// 前後の空白・改行と、LLMが付けがちな括弧・引用符を取り除いてから判定する。
    public static func validated(_ text: String) -> String? {
        let normalized = normalize(text)
        guard !normalized.isEmpty,
              normalized.count <= maxLength,
              !forbiddenPhrases.contains(where: { normalized.contains($0) }) else { return nil }

        return normalized
    }

}

private extension EncouragementToneValidator {

    static let enclosingCharacters: Set<Character> = ["「", "」", "『", "』", "\"", "“", "”"]

    static func normalize(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while let first = normalized.first, enclosingCharacters.contains(first) {
            normalized.removeFirst()
        }
        while let last = normalized.last, enclosingCharacters.contains(last) {
            normalized.removeLast()
        }
        return normalized
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
