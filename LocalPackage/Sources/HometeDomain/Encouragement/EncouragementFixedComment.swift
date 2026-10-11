//
//  EncouragementFixedComment.swift
//  LocalPackage
//

import Foundation

/// あらかじめ用意したコメント
///
/// 自分の実績がまだない日と、Foundation Modelsで生成できないときに出す。
/// 同じ日は同じ文言を出し、前日と同じ文言が続かないよう、日付の通し番号で順に選ぶ。
public enum EncouragementFixedComment {

    /// 自分の実績がまだない日の、中立・励ましの文言
    ///
    /// 何もしていないことには触れず、責めない。
    static let neutralTexts = [
        "今日はゆっくり過ごせていますか。できることから、少しずつで大丈夫です",
        "おうちのことは、みんなで少しずつ。今日も無理のないペースでいきましょう",
        "今日も一日おつかれさまです。気が向いたときに、家事リストをのぞいてみてください",
    ]

    /// 今日の家事に取りかかっている日の、ねぎらいの文言
    static let inProgressTexts = [
        "今日も家事に取りかかってくれて、ありがとうございます。おつかれさまです",
        "ひとつ終わるだけで、おうちが少し整います。いいペースですね",
        "毎日の積み重ねが、心地よい暮らしにつながっています。今日もおつかれさまです",
    ]

    /// 今日の家事が全て終わった日の、ねぎらいの文言
    static let allCompletedTexts = [
        "今日の家事がすべて終わりました。ゆっくり休んでくださいね",
        "今日もおうちのこと、おつかれさまでした。すっきりした気持ちで過ごせますように",
        "今日の家事、ぜんぶ片づきましたね。みんなで回せた一日に、おつかれさまです",
    ]

    /// 節目と日付に合わせた固定文言を返す
    public static func make(milestone: EncouragementMilestone, now: Date, calendar: Calendar) -> EncouragementComment {
        let texts = texts(for: milestone)
        let text = texts[dayNumber(of: now, calendar: calendar) % texts.count]
        let kind: EncouragementComment.Kind = milestone == .noActivity ? .neutral : .selfPraise
        return .init(text: text, kind: kind, source: .fixed)
    }

    /// すべての固定文言。禁止表現を含まないことの検証に使う
    static var allTexts: [String] {
        neutralTexts + inProgressTexts + allCompletedTexts
    }

}

private extension EncouragementFixedComment {

    /// 1970年1月1日からの日数。同じ日なら時刻によらず同じ値になる
    ///
    /// `ordinality(of: .day, in: .era)`は同じ日でも時刻によって値がずれることがあるため使わない。
    static func dayNumber(of date: Date, calendar: Calendar) -> Int {
        let origin = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let days = calendar.dateComponents([.day], from: origin, to: calendar.startOfDay(for: date)).day ?? 0
        return max(days, 0)
    }

    static func texts(for milestone: EncouragementMilestone) -> [String] {
        switch milestone {
        case .noActivity:
            neutralTexts

        case .inProgress:
            inProgressTexts

        case .allCompleted:
            allCompletedTexts
        }
    }

}
