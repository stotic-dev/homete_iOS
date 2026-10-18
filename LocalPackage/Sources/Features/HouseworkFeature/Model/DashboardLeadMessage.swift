//
//  DashboardLeadMessage.swift
//  LocalPackage
//

/// ホームのカードの上の段に出すメッセージ
///
/// カードが混み合わないよう、上の段に出すのは1つだけにする。届いたありがとうはこれとは別に、下の段に出す。
/// caseの並びが優先度の高い順で、過去の家事のありがとう漏れは今日の促しとねぎらいの間に入れる。
public enum DashboardLeadMessage: Equatable, Sendable {

    /// 今日の家事のありがとう漏れ（感謝の促し）
    case thanksPrompt(ThanksPromptSummary)
    /// ねぎらいのコメント
    case encouragement

}

public extension DashboardLeadMessage {

    /// 出せるメッセージのうち、最も優先度の高いものを選ぶ
    static func select(thanksPrompt: ThanksPromptSummary) -> Self {
        if thanksPrompt.shouldPrompt {
            return .thanksPrompt(thanksPrompt)
        }
        return .encouragement
    }

}
