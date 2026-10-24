//
//  HouseworkIntentService+Voice.swift
//  LocalPackage
//

import Foundation
import HometeDomain
import HouseworkFeature

/// 声で伝えた家事の名前から探した、今日の家事といつもの家事
struct VoiceHouseworkPlan: Equatable {

    /// 前後の空白を除いた家事の名前
    let title: String
    /// 今日の家事にある、名前が同じ家事
    let todayMatch: TodayHouseworkMatch?
    /// 名前が似ている今日の未完了の家事の名前（似ている順。名前が同じ家事は`todayMatch`に入れ、ここには入れない）
    let todaySuggestions: [String]
    /// 名前が似ているいつもの家事（似ている順）
    let suggestions: [FrequentHouseworkItem]
    /// 補足のメモが、プランで書ける文字数を超えているか
    let isNoteTooLong: Bool

}

/// 今日の家事にある、名前が同じ家事
enum TodayHouseworkMatch: Equatable {

    /// 未完了の家事（同じ名前が複数あれば、ダッシュボードの未完了の家事と同じ並びの先頭）
    case incomplete(HouseworkBoardItem)
    /// 終わった家事だけがある（家事の名前）
    case completed(title: String)

    /// 名前をそろえて比べ、未完了の家事を優先して探す
    init?(summary: TodayHouseworkSummary, title: String) {
        let key = HouseworkTitleSimilarity.normalized(title)
        if let item = summary.incompleteItems.first(where: { HouseworkTitleSimilarity.normalized($0.title) == key }) {
            self = .incomplete(item)
            return
        }
        if let item = summary.allItems.first(where: {
            $0.state == .completed && HouseworkTitleSimilarity.normalized($0.title) == key
        }) {
            self = .completed(title: item.title)
            return
        }
        return nil
    }

}

/// 記録・登録する家事
enum VoiceHouseworkTarget: Equatable {

    /// 今日の家事。実行時に名前で探し直す
    case today(title: String)
    /// いつもの家事。実行時に取り直し、消されていたら名前だけの家事として扱う
    case frequent(id: String, title: String)
    /// 名前だけの家事
    case title(String)

}

/// やった家事を記録した結果
enum RecordHouseworkOutcome: Equatable {

    /// 完了にした（今日の家事に無ければ、新しく作って完了にした）
    case completed(title: String, point: Int)
    /// その名前の家事は、今日はもう終わっている
    case alreadyCompleted(title: String)
    /// 通信できず、書き込みを端末に保存した。オンラインになったら反映される
    case pendingSync(title: String)

}

/// これからやる家事を登録した結果
enum RegisterHouseworkOutcome: Equatable {

    /// 今日の家事に登録した
    case registered(title: String)
    /// その名前の未完了の家事が、今日の家事にもうある
    case alreadyRegistered(title: String)
    /// 補足のメモが、プランで書ける文字数を超えている
    case memoLimitExceeded
    /// 通信できず、書き込みを端末に保存した。オンラインになったら反映される
    case pendingSync(title: String)

}

/// 記録・登録する家事の中身を決める
extension HouseworkIntentService {

    /// 登録画面の「新しく入力」と同じ、名前だけで作る家事のポイント
    static let defaultPoint = 10

    /// 記録・登録する家事の中身
    struct ResolvedTarget {

        let title: String
        let point: Int
        let memo: HouseworkMemo?
        let isFrequent: Bool

    }

    /// いつもの家事は取り直して、今のポイントとメモを使う
    /// - Note: いつもの家事を一時的に読めなかったときも、消されたときと同じく名前だけの家事として扱う
    func resolve(_ target: VoiceHouseworkTarget, session: AppIntentSession) async throws -> ResolvedTarget {
        switch target {
        case let .frequent(id, title):
            let context = await sessionUseCase.fetchFrequentHousework(session: session)
            guard let item = context.items.first(where: { $0.id == id }) else {
                return .init(title: title, point: Self.defaultPoint, memo: nil, isFrequent: false)
            }
            return .init(title: item.title, point: item.point, memo: item.memo, isFrequent: true)

        case let .today(title), let .title(title):
            return .init(
                title: FrequentHouseworkContext.normalize(title),
                point: Self.defaultPoint,
                memo: nil,
                isFrequent: false
            )
        }
    }

    /// 今日の家事として新しく作る家事
    /// - Parameter note: メモのテキストの後ろに足す補足
    func makeNewItem(_ target: ResolvedTarget, session: AppIntentSession, now: Date, note: String) -> HouseworkItem {
        .init(
            id: idGenerator(),
            title: target.title,
            point: target.point,
            metaData: .init(
                selectedDate: now,
                calendar: calendar,
                storagePolicy: HouseworkStoragePolicy(isPremium: session.account.isPremium)
            ),
            memo: makeMemo(target.memo, note: note)
        )
    }

    /// 名前が似ている今日の未完了の家事の名前（似ている順、同じ名前は1つにまとめる）
    /// - Note: 名前をそろえて同じ家事は`TodayHouseworkMatch`で扱うため含めない
    func similarIncompleteTitles(_ summary: TodayHouseworkSummary, title: String, limit: Int = 5) -> [String] {
        let key = HouseworkTitleSimilarity.normalized(title)
        var titles: [(title: String, score: Double)] = []
        for item in summary.incompleteItems where HouseworkTitleSimilarity.normalized(item.title) != key {
            let score = HouseworkTitleSimilarity.score(title, item.title)
            guard score >= HouseworkTitleSimilarity.threshold,
                  !titles.contains(where: { $0.title == item.title }) else { continue }
            titles.append((item.title, score))
        }
        // 似ている度合いが同じなら、ダッシュボードの未完了の家事と同じ並びのまま
        return titles.enumerated()
            .sorted { ($0.element.score, -$0.offset) > ($1.element.score, -$1.offset) }
            .prefix(limit)
            .map(\.element.title)
    }

    func trimmed(_ note: String?) -> String {
        note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// 補足だけで、プランで書ける文字数を確かめる
    /// - Note: いつもの家事のメモは保存したときに確かめ済みなので、合わせて超えても登録する
    func isWithinMemoLimit(note: String, session: AppIntentSession) -> Bool {
        note.isEmpty || HouseworkMemoLimitPolicy(isPremium: session.account.isPremium)
            .canSave(.init(text: note, checklist: []), original: nil)
    }

    func makeMemo(_ memo: HouseworkMemo?, note: String) -> HouseworkMemo? {
        guard !note.isEmpty else { return memo }
        guard let memo else { return .init(text: note, checklist: []) }
        let text = memo.text.isEmpty ? note : "\(memo.text)\n\(note)"
        return .init(text: text, checklist: memo.checklist)
    }

}
