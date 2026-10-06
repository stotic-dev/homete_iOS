//
//  EncouragementCommentComponent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// ダッシュボードのコメントカード
///
/// 家事やメンバーが変わるたびにStoreへ最新の状況を渡し、ねぎらいのコメントを決め直させる。
/// 感謝の促しはその場で計算するため、ありがとうを送ればすぐに件数が変わる。
struct EncouragementCommentComponent: View {

    @Environment(EncouragementCommentStore.self) var encouragementCommentStore
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.loginContext.account.id) var ownUserId
    @Environment(\.cohabitantMembers) var members
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.registeredContentNavigationPath) var navigationPath

    static func make() -> some View {
        EncouragementCommentComponent()
    }

    var body: some View {
        let thanksPrompt = ThanksPromptSummary.make(
            storedAllItems: houseworkListStore.items,
            members: members,
            ownUserId: ownUserId,
            now: now,
            calendar: calendar
        )
        EncouragementCommentCard(
            comment: encouragementCommentStore.comment,
            thanksPrompt: thanksPrompt.shouldPrompt ? thanksPrompt : nil,
            onTapThanks: tappedThanksButton
        )
        .task(id: updateTrigger) {
            await encouragementCommentStore.update(
                members: members,
                todayTotalCount: todayTotalCount,
                now: now,
                calendar: calendar
            )
        }
        // ダッシュボードを表示するたびと、出すコメントの種類が変わったときに送る
        .task(id: shownKinds(thanksPrompt: thanksPrompt)) {
            for kind in shownKinds(thanksPrompt: thanksPrompt) {
                analyticsClient.log(.encouragementComment(.shown(kind: kind, step: .dashboard)))
            }
        }
    }

}

// MARK: プレゼンテーションロジック

private extension EncouragementCommentComponent {

    /// コメントを決め直すきっかけになる値
    struct UpdateTrigger: Equatable {

        let items: StoredAllHouseworkList
        let members: CohabitantMemberList
        let todayTotalCount: Int
        let day: Date

    }

    var updateTrigger: UpdateTrigger {
        .init(
            items: houseworkListStore.items,
            members: members,
            todayTotalCount: todayTotalCount,
            day: calendar.startOfDay(for: now)
        )
    }

    /// 今日の家事の件数。ダッシュボードの今日の家事サマリーと同じく、テンプレートの未登録分も数える
    var todayTotalCount: Int {
        TodayHouseworkSummary.make(
            storedAllItems: houseworkListStore.items,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            now: now,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
        .allItems
        .count
    }

    /// カードに出しているコメントの種類。生成を待っている間のねぎらいは数えない
    func shownKinds(thanksPrompt: ThanksPromptSummary) -> [EncouragementCommentAnalyticsKind] {
        var kinds: [EncouragementCommentAnalyticsKind] = []
        switch encouragementCommentStore.comment?.kind {
        case .selfPraise:
            kinds.append(.selfPraise)

        case .neutral:
            kinds.append(.neutral)

        case nil:
            break
        }
        if thanksPrompt.shouldPrompt {
            kinds.append(.thanksPrompt)
        }
        return kinds
    }

    func tappedThanksButton() {
        analyticsClient.log(.encouragementComment(.tapped(kind: .thanksPrompt, step: .dashboard)))
        navigationPath.push(.thanksTargetList)
    }

}
