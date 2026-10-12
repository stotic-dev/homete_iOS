//
//  ContributionSummaryComponent.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

public struct ContributionSummaryComponent: View {

    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account.id) var userId
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    /// プレビューやチュートリアルでは注入されないため、無くても描画できるようにする
    @Environment(PendingRouteStore.self) var pendingRouteStore: PendingRouteStore?

    @State var summary: AllUserPointSummary = .init()
    @State var isShowAnalytics = false

    public static func make() -> some View {
        ContributionSummaryComponent()
    }

    public var body: some View {
        ContributionSummaryContent(isShowAnalytics: $isShowAnalytics, summaries: summary)
            .onChange(of: members) {
                Task {
                    await onChangeContribution()
                }
            }
            .task(id: contributionStore.contiribution) {
                await onChangeContribution()
            }
            // App Intentから分析画面を開く。分析画面への遷移はこのコンポーネントが持っている
            .onChange(of: pendingRouteStore?.pendingRoute, initial: true) {
                if pendingRouteStore?.takeContributionAnalytics() == true {
                    isShowAnalytics = true
                }
            }
            .navigationDestination(isPresented: $isShowAnalytics) {
                ContributionAnalyticsScreen.make()
                    .environment(contributionStore)
            }
    }

}

private extension ContributionSummaryComponent {

    func onChangeContribution() async {
        let contribution = contributionStore.contiribution
        print("did change contribution: \(contribution), members: \(members)")

        let myUserId = userId

        let summary = await Task.detached {
            await contribution.calculatePointSummaries(
                month: now,
                calendar: calendar,
                members: members,
                myUserId: myUserId
            )
        }.value

        withAnimation {
            self.summary = summary
        }
    }

}

struct ContributionSummaryContent: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.now) var now

    @Binding var isShowAnalytics: Bool

    let summaries: AllUserPointSummary

    var body: some View {
        VStack(alignment: .leading, spacing: .space24) {
            Text(monthTitle)
                .font(with: .headLineM)
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if summaries.hasData {
                MemberShareSummary(items: summaries.items.map { item in
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
                showAnalyticsButton
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - UI定義

private extension ContributionSummaryContent {

    var showAnalyticsButton: some View {
        Button(.localized("もっと詳しく見る")) {
            isShowAnalytics = true
        }
        .subPrimaryButtonStyle()
        .frame(maxWidth: .infinity)
    }

    var emptyContent: some View {
        VStack(spacing: .space8) {
            HometteView(.cheer)
            Text("今月の記録はまだありません。家事をひとつ終えると、ここに表示されます", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
            Text("これまでの貢献履歴なら振り返れます", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
                .frame(height: .space16)
            showAnalyticsButton
        }
        .frame(maxWidth: .infinity)
    }

    var monthTitle: LocalizedStringResource {
        // 月の表し方（10月 / October）は言語で変わるため、数字ではなく月の名前を差し込む
        let month = now.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).month(.wide)
        )
        return .localized("\(month)のがんばり", comment: "月の名前が入る（例: 10月のがんばり）")
    }

}

#if DEBUG
#Preview("ContributionSummaryContent_データ有り", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        isShowAnalytics: .constant(false),
        summaries: AllUserPointSummary(items: [
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
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}

#Preview("ContributionSummaryContent_データ無し", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        isShowAnalytics: .constant(false),
        summaries: AllUserPointSummary(items: [])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}
#endif
