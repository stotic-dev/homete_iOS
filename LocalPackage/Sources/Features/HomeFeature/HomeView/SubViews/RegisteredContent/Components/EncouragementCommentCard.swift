//
//  EncouragementCommentCard.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// ダッシュボードの先頭に出すカード。上の段に感謝の促し・過去の促し・ねぎらいのコメントのどれかを、下の段に届いたありがとうを出す
///
/// 何を出すかは呼び出し側が決め、このカードは渡された値を描いてタップを伝えるだけにする。
struct EncouragementCommentCard: View {

    /// 上の段に出すメッセージ
    let leadMessage: DashboardLeadMessage
    /// ねぎらいのコメント。生成を待っている間は`nil`
    let comment: EncouragementComment?
    /// 自分の家事に届いたありがとう。出さなければ`nil`
    let receivedThanks: ReceivedThanksSummary?
    /// 感謝の促しの「ありがとうを伝える」をタップした
    let onTapThanks: () -> Void
    /// 過去の促しの「ありがとうを伝える」をタップした
    let onTapPastThanks: () -> Void
    /// 届いたありがとうを×で閉じた
    let onTapDismissReceivedThanks: () -> Void
    /// AIが作成したコメントを評価した
    let onRate: (EncouragementCommentAnalyticsRating) -> Void

    @State var isShowAIInfo = false
    /// 評価済みのコメント。コメントが作り直されたら、また評価できるようにする
    @State var ratedComment: EncouragementComment?

    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            switch leadMessage {
            case let .thanksPrompt(thanksPrompt):
                thanksPromptContent(message: thanksPromptMessage(thanksPrompt), onTap: onTapThanks)

            case let .pastThanksPrompt(pastThanksPrompt):
                thanksPromptContent(message: pastThanksPromptMessage(pastThanksPrompt), onTap: onTapPastThanks)

            case .encouragement:
                commentContent()
            }
            if let receivedThanks {
                Divider()
                receivedThanksContent(receivedThanks)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: UI定義

private extension EncouragementCommentCard {

    func commentContent() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            // ホームのあいさつとして、ほめっとを添える
            HometteView(.normal, size: .small)
            // 生成を待つ間は、同じくらいの長さの文で枠だけを出し、カードの高さが変わらないようにする
            commentText
                .font(with: .body)
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .redacted(reason: comment == nil ? .placeholder : [])
                // 枠だけを出している間に、仮の文をVoiceOverで読み上げないようにする
                .accessibilityLabel(commentAccessibilityLabel)
            if let comment, comment.source == .generated {
                Spacer(minLength: .zero)
                aiBadge(comment)
            }
        }
    }

    /// AIが作成したことを示すバッジ。タップすると説明と評価のポップアップを出す
    func aiBadge(_ comment: EncouragementComment) -> some View {
        Button {
            isShowAIInfo = true
        } label: {
            HStack(spacing: .space4) {
                Text(verbatim: "AI")
                    .font(with: .boldCaption)
                Image(systemName: "info.circle")
                    .font(with: .caption)
            }
            .foregroundStyle(.textAccent)
            .padding(.horizontal, .space8)
            .padding(.vertical, .space4)
            .overlay {
                Capsule()
                    .stroke(.fillAccent)
            }
        }
        .accessibilityLabel(.localized("AIが作成したコメントについて"))
        .popover(isPresented: $isShowAIInfo) {
            EncouragementAICommentPopover(isRated: ratedComment == comment) { rating in
                ratedComment = comment
                onRate(rating)
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    func thanksPromptContent(message: LocalizedStringResource, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: .space16) {
            HStack(alignment: .top, spacing: .space8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.fillAccent)
                    .accessibilityHidden(true)
                Text(message)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(.localized("ありがとうを伝える")) {
                onTap()
            }
            .primaryButtonStyle()
        }
    }

    func receivedThanksContent(_ receivedThanks: ReceivedThanksSummary) -> some View {
        HStack(alignment: .top, spacing: .space8) {
            HometteSpeechView(.thanks, message: receivedThanksMessage(receivedThanks))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onTapDismissReceivedThanks()
            } label: {
                Image(systemName: "xmark")
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
                    // 小さな印でも押しやすいよう、タップできる範囲を広げる
                    .frame(width: 44, height: 44, alignment: .topTrailing)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(.localized("届いたありがとうを閉じる"))
        }
    }

    /// コメントの本文。生成を待つ間は、同じくらいの長さの仮の文を出す
    ///
    /// 本文はAIが作成した文や固定の文言をそのまま出すため、翻訳しない。
    var commentText: Text {
        guard let comment else {
            return Text("今日もおうちのこと、おつかれさまです。ゆっくり休んでくださいね", bundle: #bundle)
        }

        return Text(verbatim: comment.text)
    }

    var commentAccessibilityLabel: Text {
        guard let comment else {
            return Text("コメントを準備しています", bundle: #bundle)
        }

        return Text(verbatim: comment.text)
    }

    /// 相手がやってくれたことに焦点を当て、自分がまだ送っていないことには触れない
    func thanksPromptMessage(_ thanksPrompt: ThanksPromptSummary) -> LocalizedStringResource {
        let count = thanksPrompt.notSentCount
        guard !thanksPrompt.executorNames.isEmpty else {
            return .localized("\(count)件の家事をしてもらいました。ありがとうを伝えてみませんか？")
        }

        let names = joinedNames(thanksPrompt.executorNames)
        return .localized(
            "\(names)が\(count)件の家事をしてくれました。ありがとうを伝えてみませんか？",
            comment: "1つめは家事をした人の名前を並べたもの、2つめは家事の件数"
        )
    }

    /// 過去の家事へのありがとうは遅れて伝えるものなので、忘れていたことを責めるような言い方は避ける
    func pastThanksPromptMessage(_ pastThanksPrompt: PastThanksPromptSummary) -> LocalizedStringResource {
        let count = pastThanksPrompt.notSentCount
        guard !pastThanksPrompt.executorNames.isEmpty else {
            return .localized("この数日で、\(count)件の家事をしてもらいました。ありがとうを伝えてみませんか？")
        }

        let names = joinedNames(pastThanksPrompt.executorNames)
        return .localized(
            "この数日で、\(names)が\(count)件の家事をしてくれました。ありがとうを伝えてみませんか？",
            comment: "1つめは家事をした人の名前を並べたもの、2つめは家事の件数"
        )
    }

    /// ほめっとのセリフ。ほめっとの言葉なので、くだけた口調にする
    func receivedThanksMessage(_ receivedThanks: ReceivedThanksSummary) -> LocalizedStringResource {
        let count = receivedThanks.count
        // 送ってくれた人がグループを抜けていると、名前を出せない
        guard !receivedThanks.senderNames.isEmpty else {
            return .localized("「ありがとう」が\(count)件届いたよ", comment: "ほめっとのセリフ。自分の家事に届いたありがとうの件数が入る")
        }

        let names = joinedNames(receivedThanks.senderNames)
        guard count > 1 else {
            return .localized("\(names)から「ありがとう」が届いたよ", comment: "ほめっとのセリフ。ありがとうを送ってくれた人の名前が入る")
        }

        return .localized(
            "\(names)から「ありがとう」が\(count)件届いたよ",
            comment: "ほめっとのセリフ。1つめはありがとうを送ってくれた人の名前を並べたもの、2つめは届いた件数"
        )
    }

    /// メンバーの名前に敬称を付けて並べる（例: Aさん・Bさん）
    func joinedNames(_ names: [String]) -> String {
        names
            .map { LocalizedStringResource.localized("\($0)さん", comment: "家事をした人の名前に付ける敬称").resolved() }
            .joined(separator: LocalizedStringResource.localized("・", comment: "名前を並べるときの区切り（例: Aさん・Bさん）").resolved())
    }

}

/// AIが作成したコメントの説明と、good/badの評価を出すポップアップ
struct EncouragementAICommentPopover: View {

    /// このコメントを評価済みか
    let isRated: Bool
    let onRate: (EncouragementCommentAnalyticsRating) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            VStack(alignment: .leading, spacing: .space8) {
                Text("AIが作成したコメントです", bundle: #bundle)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Text("家事の記録をもとに、端末内のAIが作成しました。記録が端末の外へ送られることはありません。", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            if isRated {
                Text("ご意見ありがとうございます。今後のコメントづくりの参考にします", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ratingContent()
            }
        }
        .padding(.space16)
        .frame(width: 260)
    }

}

private extension EncouragementAICommentPopover {

    func ratingContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("このコメントはいかがでしたか？", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textPrimary)
            HStack(spacing: .space8) {
                Button {
                    onRate(.good)
                } label: {
                    Label(.localized("よかった"), systemImage: "hand.thumbsup")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    onRate(.bad)
                } label: {
                    Label(.localized("いまいち"), systemImage: "hand.thumbsdown")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .tint(.fillAccent)
            .font(with: .caption)
        }
    }

}

#if DEBUG
#Preview("EncouragementCommentCard_感謝の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .thanksPrompt(.init(thankableItems: [], notSentCount: 3, executorNames: ["はなこ"])),
        comment: nil,
        receivedThanks: nil,
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_複数人への感謝の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .thanksPrompt(.init(thankableItems: [], notSentCount: 5, executorNames: ["はなこ", "じろう"])),
        comment: nil,
        receivedThanks: nil,
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_過去の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .pastThanksPrompt(.init(dailyItems: [], notSentCount: 3, executorNames: ["はなこ"])),
        comment: nil,
        receivedThanks: nil,
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_ねぎらいのみ", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .encouragement,
        comment: .init(
            text: "今日も一日おつかれさまです。気が向いたときに、家事リストをのぞいてみてください",
            kind: .neutral,
            source: .fixed
        ),
        receivedThanks: nil,
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_ありがとうが届いた", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .encouragement,
        comment: .init(
            text: "今日も洗い物と洗濯、おつかれさまです。3日続けて家事をしていて、すてきですね",
            kind: .selfPraise,
            source: .generated
        ),
        receivedThanks: .init(count: 2, senderNames: ["はなこ"], latestSentAt: nil),
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_感謝の促しとありがとうが届いた", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .thanksPrompt(.init(thankableItems: [], notSentCount: 1, executorNames: ["はなこ"])),
        comment: nil,
        receivedThanks: .init(count: 1, senderNames: ["はなこ"], latestSentAt: nil),
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_生成中", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        leadMessage: .encouragement,
        comment: nil,
        receivedThanks: nil,
        onTapThanks: {},
        onTapPastThanks: {},
        onTapDismissReceivedThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementAICommentPopover_評価前", traits: .sizeThatFitsLayout) {
    EncouragementAICommentPopover(isRated: false, onRate: { _ in })
}

#Preview("EncouragementAICommentPopover_評価後", traits: .sizeThatFitsLayout) {
    EncouragementAICommentPopover(isRated: true, onRate: { _ in })
}
#endif
