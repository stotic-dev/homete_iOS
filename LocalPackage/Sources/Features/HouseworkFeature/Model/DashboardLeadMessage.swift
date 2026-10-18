//
//  DashboardLeadMessage.swift
//  LocalPackage
//

/// ホームのカードの上の段に出すメッセージ
///
/// カードが混み合わないよう、上の段に出すのは1つだけにする。届いたありがとうはこれとは別に、下の段に出す。
/// caseの並びが優先度の高い順。
public enum DashboardLeadMessage: Equatable, Sendable {

    /// 今日の家事のありがとう漏れ（感謝の促し）
    case thanksPrompt(ThanksPromptSummary)
    /// 昨日から7日前までの家事のありがとう漏れ（過去の促し）
    case pastThanksPrompt(PastThanksPromptSummary)
    /// ねぎらいのコメント
    case encouragement

}

public extension DashboardLeadMessage {

    /// 出せるメッセージのうち、最も優先度の高いものを選ぶ
    ///
    /// - Parameter canShowPastThanksPrompt: 過去の促しを、今日の表示回数の上限までに出せるか
    static func select(
        thanksPrompt: ThanksPromptSummary,
        pastThanksPrompt: PastThanksPromptSummary,
        canShowPastThanksPrompt: Bool
    ) -> Self {
        if thanksPrompt.shouldPrompt {
            return .thanksPrompt(thanksPrompt)
        }
        if pastThanksPrompt.shouldPrompt, canShowPastThanksPrompt {
            return .pastThanksPrompt(pastThanksPrompt)
        }
        return .encouragement
    }

}
