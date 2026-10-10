//
//  EncouragementPrompt.swift
//  LocalPackage
//

/// Foundation Modelsに渡すinstructionsとプロンプト
///
/// トーンのガイドラインはinstructionsで指示し、生成結果は`EncouragementToneValidator`でも検証する。
/// 同居人の実績も渡すため、比較・順位づけをしないことを特に強く指示する。
public enum EncouragementPrompt {

    /// モデルの振る舞いを決める指示
    public static let instructions = """
    あなたは、同居人と家事を分担する家事管理アプリの中で、利用者をねぎらう短いコメントを書きます。
    渡された家事の実施状況をもとに、利用者本人に向けたあたたかいひとことを、日本語の敬体で1文から2文、\(EncouragementToneValidator.maxLength)文字以内で書いてください。

    守ること:
    - 利用者本人が終えた家事や続けてきたことを、具体的に認めてねぎらう
    - 同居人の実績は「一緒に家事を回していること」を認める材料にだけ使う
    - 人と人を比べない。どちらが多い・少ない、割合、差、順位には一切触れない
    - 家事の量の少なさや偏りを責めない。「もっと〜」「〜すべき」のような要求や評価をしない
    - まだ終わっていない家事や、遅れには触れない
    - 数字は、利用者本人の件数や続けた日数をねぎらうときにだけ使う
    - コメント本文だけを出力し、かぎかっこや前置きを付けない
    """

    /// 実施状況をモデルに渡す文章にする
    public static func prompt(context: EncouragementContext) -> String {
        var lines = ["次の状況をもとに、利用者本人へのねぎらいのコメントを書いてください。", ""]
        lines.append("【利用者本人の実績】")
        lines.append(contentsOf: ownLines(context.own))
        lines.append("")
        lines.append("【今日の家事（世帯全体）】")
        lines.append(contentsOf: todayLines(context.today))
        if !context.monthlyMembers.isEmpty {
            lines.append("")
            lines.append("【今月の家事（メンバー別）】")
            lines.append(contentsOf: context.monthlyMembers.map(memberLine))
        }
        return lines.joined(separator: "\n")
    }

}

private extension EncouragementPrompt {

    static func ownLines(_ own: EncouragementContext.OwnActivity) -> [String] {
        var lines = ["- 今日終えた家事: \(own.todayCompletedCount)件"]
        if !own.todayCompletedTitles.isEmpty {
            lines.append("- 今日終えた家事の内容: \(own.todayCompletedTitles.joined(separator: "、"))")
        }
        if own.todayEffortfulCount > 0 {
            lines.append("- そのうち、がんばって終えた家事: \(own.todayEffortfulCount)件")
        }
        lines.append("- 直近7日間に終えた家事: \(own.weeklyCompletedCount)件")
        if own.streakDays >= 2 {
            lines.append("- 家事をした日が\(own.streakDays)日続いている")
        }
        return lines
    }

    static func todayLines(_ today: EncouragementContext.TodayProgress) -> [String] {
        var lines = ["- 今日終わった家事: \(today.completedCount)件"]
        if today.isAllCompleted {
            lines.append("- 今日の家事はすべて終わった")
        }
        return lines
    }

    static func memberLine(_ member: EncouragementContext.MonthlyMemberContribution) -> String {
        let name = member.isOwn ? "利用者本人" : "\(member.userName)さん"
        var line = "- \(name): \(member.completedCount)件、\(member.point)ポイント"
        if !member.frequentTitles.isEmpty {
            line += "（よくした家事: \(member.frequentTitles.joined(separator: "、"))）"
        }
        return line
    }

}
