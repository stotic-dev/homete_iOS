//
//  ContributionSummaryTutorialContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// チュートリアルで、ダッシュボードの貢献度サマリーをサンプルの値で表示する
///
/// 本番と同じ`ContributionSummaryContent`にサンプルを渡すだけで、集計や画面遷移は行わない。
public struct ContributionSummaryTutorialContent: View {

    let members: CohabitantMemberList

    public init(members: CohabitantMemberList) {
        self.members = members
    }

    public var body: some View {
        ContributionSummaryContent(
            isShowAnalytics: .constant(false),
            summaries: .init(items: members.value.enumerated().map { index, member in
                // 自分が少し多めに見えるよう、並び順でポイントに差を付ける
                UserPointSummary(
                    userId: member.id,
                    userName: member.userName,
                    isMe: member.id == members.ownId,
                    monthlyPoint: .init(value: 120 - index * 40),
                    achievedCount: 6 - index * 2
                )
            })
        )
    }

}

#if DEBUG
#Preview("ContributionSummaryTutorialContent", traits: .sizeThatFitsLayout) {
    ContributionSummaryTutorialContent(members: .init(
        value: [
            .init(id: "ownUserId", userName: "たろう"),
            .init(id: "otherUserId", userName: "はなこ"),
        ],
        ownId: "ownUserId"
    ))
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}
#endif
