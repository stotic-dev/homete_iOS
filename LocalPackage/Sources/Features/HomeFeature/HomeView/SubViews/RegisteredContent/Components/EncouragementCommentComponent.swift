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
/// 届いたありがとうと感謝の促しはその場で計算するため、ありがとうが届いたり送ったりすればすぐに件数が変わる。
/// 届いたありがとうは一度見たら次からは出さない。ただし見ている途中で消えないよう、ホームを開き直したときに消す。
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
    @Environment(\.scenePhase) var scenePhase

    @AppStorage(key: .receivedThanksSeenAt) var receivedThanksSeenAt: Double = 0
    /// 届いたありがとうを数える基準にする、見た日時。ホームを開いたときの値に固定し、見たことを記録しても表示中は消さない。
    /// 開く前の描画では`nil`で、そのときは保存してある値をそのまま使う
    @State var fixedReceivedThanksSeenAt: Double?

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
        let receivedThanks = ReceivedThanksSummary.make(
            storedAllItems: houseworkListStore.items,
            members: members,
            ownUserId: ownUserId,
            seenUntil: receivedThanksSeenUntil,
            now: now,
            calendar: calendar
        )
        EncouragementCommentCard(
            comment: encouragementCommentStore.comment,
            receivedThanks: receivedThanks.hasReceived ? receivedThanks : nil,
            thanksPrompt: thanksPrompt.shouldPrompt ? thanksPrompt : nil,
            onTapThanks: tappedThanksButton,
            onRate: ratedComment
        )
        // 見たことを記録する処理と、どちらが先に走っても開いたときの値に固定されるよう、まだ固定していないときだけ読む
        .onAppear {
            if fixedReceivedThanksSeenAt == nil {
                fixedReceivedThanksSeenAt = receivedThanksSeenAt
            }
        }
        .onDisappear {
            fixedReceivedThanksSeenAt = nil
        }
        // アプリに戻ってきたときも、ホームを開き直したものとして扱う
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }

            fixedReceivedThanksSeenAt = receivedThanksSeenAt
        }
        .task(id: receivedThanks.latestSentAt) {
            markReceivedThanksAsSeen(receivedThanks)
        }
        .task(id: updateTrigger) {
            await encouragementCommentStore.update(
                ownUserId: ownUserId,
                members: members,
                todayTotalCount: todayTotalCount,
                now: now,
                calendar: calendar
            )
        }
        // ダッシュボードを表示するたびと、出すコメントの種類が変わったときに送る。
        // ねぎらいの生成を待つ間に感謝の促しだけ先に送ると、生成後にもう一度送って二重に数えてしまうため、
        // ねぎらいが決まってからまとめて送る
        .task(id: shownKinds(thanksPrompt: thanksPrompt)) {
            guard encouragementCommentStore.comment != nil else { return }

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

        /// 家事が1件もないグループでは、初回の取得が終わっても`items`が空のまま変わらないため、読み込み状態も見る
        let loadState: ListenerLoadState
        let items: StoredAllHouseworkList
        let members: CohabitantMemberList
        let todayTotalCount: Int
        let day: Date

    }

    var updateTrigger: UpdateTrigger {
        .init(
            loadState: houseworkListStore.loadState,
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

    var receivedThanksSeenUntil: Date? {
        let seenAt = fixedReceivedThanksSeenAt ?? receivedThanksSeenAt
        return seenAt > 0 ? Date(timeIntervalSince1970: seenAt) : nil
    }

    /// カードに出した、届いたありがとうを見たことにする
    func markReceivedThanksAsSeen(_ receivedThanks: ReceivedThanksSummary) {
        guard let latestSentAt = receivedThanks.latestSentAt?.timeIntervalSince1970,
              latestSentAt > receivedThanksSeenAt else { return }

        if fixedReceivedThanksSeenAt == nil {
            fixedReceivedThanksSeenAt = receivedThanksSeenAt
        }
        receivedThanksSeenAt = latestSentAt
    }

    /// カードに出しているコメントの種類
    func shownKinds(thanksPrompt: ThanksPromptSummary) -> [EncouragementCommentAnalyticsKind] {
        var kinds: [EncouragementCommentAnalyticsKind] = []
        if let comment = encouragementCommentStore.comment {
            kinds.append(analyticsKind(of: comment))
        }
        if thanksPrompt.shouldPrompt {
            kinds.append(.thanksPrompt)
        }
        return kinds
    }

    func analyticsKind(of comment: EncouragementComment) -> EncouragementCommentAnalyticsKind {
        switch comment.kind {
        case .selfPraise:
            .selfPraise

        case .neutral:
            .neutral
        }
    }

    func ratedComment(_ rating: EncouragementCommentAnalyticsRating) {
        guard let comment = encouragementCommentStore.comment else { return }

        analyticsClient.log(
            .encouragementComment(.rated(kind: analyticsKind(of: comment), rating: rating, step: .dashboard))
        )
    }

    func tappedThanksButton() {
        analyticsClient.log(.encouragementComment(.tapped(kind: .thanksPrompt, step: .dashboard)))
        navigationPath.push(.thanksTargetList)
    }

}
