//
//  EncouragementCommentCard.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// ダッシュボードの先頭に出す、ねぎらいのコメントと同居人への感謝の促し
///
/// 何を出すかは呼び出し側が決め、このカードは渡された値を描いてタップを伝えるだけにする。
struct EncouragementCommentCard: View {

    /// ねぎらいのコメント。生成を待っている間は`nil`
    let comment: EncouragementComment?
    /// 感謝の促し。ありがとうを伝えられる家事がなければ`nil`
    let thanksPrompt: ThanksPromptSummary?
    let onTapThanks: () -> Void
    /// AIが作成したコメントを評価した
    let onRate: (EncouragementCommentAnalyticsRating) -> Void

    @State var isShowAIInfo = false
    /// 評価済みのコメント。コメントが作り直されたら、また評価できるようにする
    @State var ratedComment: EncouragementComment?

    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            commentContent()
            if let thanksPrompt {
                Divider()
                thanksPromptContent(thanksPrompt)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: UI定義

private extension EncouragementCommentCard {

    func commentContent() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(.accent)
                .accessibilityHidden(true)
            // 生成を待つ間は、同じくらいの長さの文で枠だけを出し、カードの高さが変わらないようにする
            Text(comment?.text ?? "今日もおうちのこと、おつかれさまです。ゆっくり休んでくださいね")
                .font(with: .body)
                .foregroundStyle(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .redacted(reason: comment == nil ? .placeholder : [])
                // 枠だけを出している間に、仮の文をVoiceOverで読み上げないようにする
                .accessibilityLabel(comment?.text ?? "コメントを準備しています")
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
                Text("AI")
                    .font(with: .boldCaption)
                Image(systemName: "info.circle")
                    .font(with: .caption)
            }
            .foregroundStyle(.accent)
            .padding(.horizontal, .space8)
            .padding(.vertical, .space4)
            .overlay {
                Capsule()
                    .stroke(.accent)
            }
        }
        .accessibilityLabel("AIが作成したコメントについて")
        .popover(isPresented: $isShowAIInfo) {
            EncouragementAICommentPopover(isRated: ratedComment == comment) { rating in
                ratedComment = comment
                onRate(rating)
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    func thanksPromptContent(_ thanksPrompt: ThanksPromptSummary) -> some View {
        VStack(alignment: .leading, spacing: .space16) {
            HStack(alignment: .top, spacing: .space8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)
                Text(thanksPromptMessage(thanksPrompt))
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("ありがとうを伝える") {
                onTapThanks()
            }
            .primaryButtonStyle()
        }
    }

    /// 相手がやってくれたことに焦点を当て、自分がまだ送っていないことには触れない
    func thanksPromptMessage(_ thanksPrompt: ThanksPromptSummary) -> String {
        let count = thanksPrompt.notSentCount
        guard !thanksPrompt.executorNames.isEmpty else {
            return "\(count)件の家事をしてもらいました。ありがとうを伝えてみませんか？"
        }

        let names = thanksPrompt.executorNames.map { "\($0)さん" }.joined(separator: "・")
        return "\(names)が\(count)件の家事をしてくれました。ありがとうを伝えてみませんか？"
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
                Text("AIが作成したコメントです")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                Text("家事の記録をもとに、端末内のAIが作成しました。記録が端末の外へ送られることはありません。")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            if isRated {
                Text("ご意見ありがとうございます。今後のコメントづくりの参考にします")
                    .font(with: .caption)
                    .foregroundStyle(.onSurface)
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
            Text("このコメントはいかがでしたか？")
                .font(with: .caption)
                .foregroundStyle(.onSurface)
            HStack(spacing: .space8) {
                Button {
                    onRate(.good)
                } label: {
                    Label("よかった", systemImage: "hand.thumbsup")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    onRate(.bad)
                } label: {
                    Label("いまいち", systemImage: "hand.thumbsdown")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .tint(.accent)
            .font(with: .caption)
        }
    }

}

#if DEBUG
#Preview("EncouragementCommentCard_ねぎらいと感謝の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        comment: .init(
            text: "今日も洗い物と洗濯、おつかれさまです。3日続けて家事をしていて、すてきですね",
            kind: .selfPraise,
            source: .generated
        ),
        thanksPrompt: .init(thankableItems: [], notSentCount: 3, executorNames: ["はなこ"]),
        onTapThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_複数人への感謝の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        comment: .init(
            text: "今日の家事、ぜんぶ片づきましたね。みんなで回せた一日に、おつかれさまです",
            kind: .selfPraise,
            source: .fixed
        ),
        thanksPrompt: .init(thankableItems: [], notSentCount: 5, executorNames: ["はなこ", "じろう"]),
        onTapThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_ねぎらいのみ", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        comment: .init(
            text: "今日も一日おつかれさまです。気が向いたときに、家事リストをのぞいてみてください",
            kind: .neutral,
            source: .fixed
        ),
        thanksPrompt: nil,
        onTapThanks: {},
        onRate: { _ in }
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_生成中", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(comment: nil, thanksPrompt: nil, onTapThanks: {}, onRate: { _ in })
        .padding(.space16)
}

#Preview("EncouragementAICommentPopover_評価前", traits: .sizeThatFitsLayout) {
    EncouragementAICommentPopover(isRated: false, onRate: { _ in })
}

#Preview("EncouragementAICommentPopover_評価後", traits: .sizeThatFitsLayout) {
    EncouragementAICommentPopover(isRated: true, onRate: { _ in })
}
#endif
