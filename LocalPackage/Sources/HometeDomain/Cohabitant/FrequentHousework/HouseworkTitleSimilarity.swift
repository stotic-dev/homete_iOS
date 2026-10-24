//
//  HouseworkTitleSimilarity.swift
//  LocalPackage
//

import Foundation

/// 家事の名前が似ているかの判定
///
/// Siriに話しかけた言い方（「洗濯干した」）から、登録済みの家事（「洗濯物干し」）を見つけるために使う。
/// 音声入力では送り仮名・カタカナとひらがな・全角と半角の揺れが起きやすいため、それらをそろえてから比べる。
public enum HouseworkTitleSimilarity {

    /// 似ているとみなす類似度の下限
    public static let threshold = 0.4

    /// 比較に使う形にそろえる（空白を除き、カタカナをひらがなに、全角と半角・大文字と小文字をそろえる）
    public static func normalized(_ title: String) -> String {
        let folded = title.folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja"))
        let hiragana = folded.applyingTransform(.hiraganaToKatakana, reverse: true) ?? folded
        return hiragana.filter { !$0.isWhitespace }
    }

    /// 2つの名前の類似度（0〜1）
    ///
    /// そろえた名前が同じなら1、片方がもう片方を含むなら0.9、それ以外は2文字ずつの組（バイグラム）の重なり（Dice係数）で測る。
    public static func score(_ lhs: String, _ rhs: String) -> Double {
        let lhs = normalized(lhs)
        let rhs = normalized(rhs)
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        if lhs == rhs {
            return 1
        }
        // 1文字の名前は何にでも含まれやすいので、含むかどうかでは判定しない
        if min(lhs.count, rhs.count) >= 2, lhs.contains(rhs) || rhs.contains(lhs) {
            return 0.9
        }
        let lhsBigrams = bigrams(lhs)
        let rhsBigrams = bigrams(rhs)
        let common = lhsBigrams.intersection(rhsBigrams).count
        return Double(common * 2) / Double(lhsBigrams.count + rhsBigrams.count)
    }

}

private extension HouseworkTitleSimilarity {

    /// 2文字ずつの組。1文字の名前はその文字だけを返す
    static func bigrams(_ value: String) -> Set<String> {
        let characters = Array(value)
        guard characters.count > 1 else { return [value] }
        return Set((0 ..< characters.count - 1).map { String(characters[$0 ... $0 + 1]) })
    }

}

public extension FrequentHouseworkContext {

    /// 名前が似ているいつもの家事を、似ている順に返す
    ///
    /// そろえた名前が同じ家事があれば、その家事だけを返す（ほかの候補で聞き返さないため）。
    /// 類似度が同じなら、カテゴリ内の並び順で並べる。
    /// - Parameter limit: 返す件数の上限。Siriの聞き返しで選びやすい件数に絞る
    func similarItems(to title: String, limit: Int = 5) -> [FrequentHouseworkItem] {
        let scored = items
            .map { (item: $0, score: HouseworkTitleSimilarity.score(title, $0.title)) }
            .filter { $0.score >= HouseworkTitleSimilarity.threshold }
        let exactItems = scored.filter { $0.score == 1 }
        return (exactItems.isEmpty ? scored : exactItems)
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return (lhs.item.sortOrder, lhs.item.createdAt, lhs.item.id)
                    < (rhs.item.sortOrder, rhs.item.createdAt, rhs.item.id)
            }
            .prefix(limit)
            .map(\.item)
    }

}
