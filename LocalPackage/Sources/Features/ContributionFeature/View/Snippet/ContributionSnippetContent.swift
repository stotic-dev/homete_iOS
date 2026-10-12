//
//  ContributionSnippetContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// Siriの結果に出す、今月のがんばり
///
/// Siriの結果の中ではボタンを押せないため、ダッシュボードの`ContributionSummaryContent`から
/// 「もっと詳しく見る」とほめっとを除いた形にする。
/// 色はSiriの背景に任せず、背景を自前で塗る（`body`のコメント参照）。
public struct ContributionSnippetContent: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale

    let summary: ContributionMonthlySummary

    public init(summary: ContributionMonthlySummary) {
        self.summary = summary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text(monthTitle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if summary.hasData {
                MemberShareSummary(items: summary.pointSummary.items.map { item in
                    .init(
                        id: item.userId,
                        name: item.userName,
                        value: item.monthlyPoint.value,
                        detail: .localized(
                            "\(item.achievedCount)件・\(item.monthlyPoint.value)pt",
                            comment: "メンバーが今月終えた家事の件数と、もらったポイント"
                        )
                    )
                })
            } else {
                Text("今月の記録はまだありません。家事をひとつ終えると、ここに表示されます", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // SiriがダークモードでもこのViewにライトモードを渡すことがあり、Siriの暗い背景にライトモードの文字色が載って読めなくなる。
        // 背景も文字と同じ外観の色で塗り、どちらの外観を渡されても文字と背景の組み合わせが崩れないようにする
        .background(.backgroundCard)
    }

}

private extension ContributionSnippetContent {

    var monthTitle: LocalizedStringResource {
        // 月の表し方（10月 / October）は言語で変わるため、数字ではなく月の名前を差し込む
        let month = summary.month.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).month(.wide)
        )
        return .localized("\(month)のがんばり", comment: "月の名前が入る（例: 10月のがんばり）")
    }

}

#if DEBUG
#Preview("ContributionSnippetContent_データ有り", traits: .sizeThatFitsLayout) {
    ContributionSnippetContent(summary: .init(
        month: .previewDate(year: 2026, month: 4, day: 1),
        pointSummary: .init(items: [
            UserPointSummary(
                userId: "user1",
                userName: "田中",
                isMe: true,
                monthlyPoint: .init(value: 120),
                achievedCount: 5
            ),
            UserPointSummary(
                userId: "user2",
                userName: "佐藤",
                isMe: false,
                monthlyPoint: .init(value: 40),
                achievedCount: 2
            ),
        ])
    ))
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("ContributionSnippetContent_データ無し", traits: .sizeThatFitsLayout) {
    ContributionSnippetContent(summary: .init(
        month: .previewDate(year: 2026, month: 4, day: 1),
        pointSummary: .init(items: [])
    ))
    .setupEnvironmentForPreview()
}
#endif
