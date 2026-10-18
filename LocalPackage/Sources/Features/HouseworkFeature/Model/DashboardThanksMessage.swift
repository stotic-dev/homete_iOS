//
//  DashboardThanksMessage.swift
//  LocalPackage
//

/// ホームのカードで、ねぎらいのコメントに添えて出すありがとうのメッセージ
///
/// カードが混み合わないよう、同時に出すのは1つだけにする。ねぎらいのコメントはこれとは別に常に出す。
/// caseの並びが優先度の高い順で、過去の家事のありがとう漏れは今日の促しと届いたありがとうの間に入れる。
public enum DashboardThanksMessage: Equatable, Sendable {

    /// 今日の家事のありがとう漏れ（感謝の促し）
    case thanksPrompt(ThanksPromptSummary)
    /// 自分の家事に届いたありがとう
    case receivedThanks(ReceivedThanksSummary)

}

public extension DashboardThanksMessage {

    /// 出せるメッセージのうち、最も優先度の高いものを選ぶ
    ///
    /// - Parameter receivedThanks: 届いたありがとう。表示回数の上限や×で出さない場合は`nil`を渡す
    /// - Returns: 出せるメッセージがなければ`nil`
    static func select(thanksPrompt: ThanksPromptSummary, receivedThanks: ReceivedThanksSummary?) -> Self? {
        if thanksPrompt.shouldPrompt {
            return .thanksPrompt(thanksPrompt)
        }
        if let receivedThanks, receivedThanks.hasReceived {
            return .receivedThanks(receivedThanks)
        }
        return nil
    }

    /// 届いたありがとうを出しているか
    var isReceivedThanks: Bool {
        if case .receivedThanks = self {
            return true
        }
        return false
    }

}
