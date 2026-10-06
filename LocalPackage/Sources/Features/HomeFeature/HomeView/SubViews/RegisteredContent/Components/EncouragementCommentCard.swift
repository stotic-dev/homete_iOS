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

#if DEBUG
#Preview("EncouragementCommentCard_ねぎらいと感謝の促し", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(
        comment: .init(
            text: "今日も洗い物と洗濯、おつかれさまです。3日続けて家事をしていて、すてきですね",
            kind: .selfPraise,
            source: .generated
        ),
        thanksPrompt: .init(thankableItems: [], notSentCount: 3, executorNames: ["はなこ"]),
        onTapThanks: {}
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
        onTapThanks: {}
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
        onTapThanks: {}
    )
    .padding(.space16)
}

#Preview("EncouragementCommentCard_生成中", traits: .sizeThatFitsLayout) {
    EncouragementCommentCard(comment: nil, thanksPrompt: nil, onTapThanks: {})
        .padding(.space16)
}
#endif
