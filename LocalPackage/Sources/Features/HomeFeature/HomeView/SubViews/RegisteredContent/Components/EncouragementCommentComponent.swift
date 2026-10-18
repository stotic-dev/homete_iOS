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
/// 感謝の促しと届いたありがとうはその場で計算するため、ありがとうが届いたり送ったりすればすぐに件数が変わる。
/// ねぎらいに添えるのは、そのうち優先度の高い1つだけ（`DashboardThanksMessage`）。
/// 届いたありがとうは、ホームが出るたびに1回と数えて1日に3回まで出し、×で閉じたらその日は出さない。
/// 優先度で隠れて出さなかった回は数えない。
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

    @AppStorage(key: .receivedThanksDisplayRecord) var storedReceivedThanksRecord = ReceivedThanksDisplayRecord()
    /// ホームが出た回の通し番号。タブの切り替え・push先からの戻り・アプリへの復帰で進める
    @State var appearance = 0
    /// 届いたありがとうを出した回として数えた、ホームが出た回の通し番号。表示中に上限に達しても消さないために使う
    @State var receivedThanksCountedAppearance: Int?

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
            now: now,
            calendar: calendar
        )
        let receivedThanksRecord = storedReceivedThanksRecord.reconciled(
            with: receivedThanks,
            now: now,
            calendar: calendar
        )
        let thanksMessage = DashboardThanksMessage.select(
            thanksPrompt: thanksPrompt,
            receivedThanks: receivedThanksRecord.canShow(
                receivedThanks,
                isCountedInCurrentAppearance: receivedThanksCountedAppearance == appearance
            ) ? receivedThanks : nil
        )
        EncouragementCommentCard(
            comment: encouragementCommentStore.comment,
            thanksMessage: thanksMessage,
            onTapThanks: tappedThanksButton,
            onTapDismissReceivedThanks: { dismissReceivedThanks(receivedThanks) },
            onRate: ratedComment
        )
        .onAppear {
            appearance += 1
        }
        // アプリに戻ってきたときも、ホームが出たものとして扱う
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }

            appearance += 1
        }
        // 届いたありがとうを実際に出したときだけ数え、優先度で隠れている間は数えない
        .task(id: ReceivedThanksCountTrigger(
            appearance: appearance,
            isShown: thanksMessage?.isReceivedThanks == true
        )) {
            countReceivedThanksIfShown(thanksMessage, receivedThanks: receivedThanks)
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
        // ねぎらいの生成を待つ間に添えるメッセージだけ先に送ると、生成後にもう一度送って二重に数えてしまうため、
        // ねぎらいが決まってからまとめて送る
        .task(id: shownKinds(thanksMessage: thanksMessage)) {
            guard encouragementCommentStore.comment != nil else { return }

            for kind in shownKinds(thanksMessage: thanksMessage) {
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

    /// 届いたありがとうを出した回として数えるきっかけになる値
    struct ReceivedThanksCountTrigger: Equatable {

        let appearance: Int
        let isShown: Bool

    }

    /// 届いたありがとうを出していれば、ホームが出た回ごとに1回だけ数える
    func countReceivedThanksIfShown(_ thanksMessage: DashboardThanksMessage?, receivedThanks: ReceivedThanksSummary) {
        guard thanksMessage?.isReceivedThanks == true,
              receivedThanksCountedAppearance != appearance else { return }

        var record = storedReceivedThanksRecord.reconciled(with: receivedThanks, now: now, calendar: calendar)
        record.recordShown()
        storedReceivedThanksRecord = record
        receivedThanksCountedAppearance = appearance
    }

    func dismissReceivedThanks(_ receivedThanks: ReceivedThanksSummary) {
        analyticsClient.log(.encouragementComment(.dismissed(kind: .receivedThanks, step: .dashboard)))
        var record = storedReceivedThanksRecord.reconciled(with: receivedThanks, now: now, calendar: calendar)
        record.dismiss(receivedThanks)
        withAnimation {
            storedReceivedThanksRecord = record
            // 閉じた後に新しいありがとうが届いて出し直すときは、その回をあらためて数える
            receivedThanksCountedAppearance = nil
        }
    }

    /// カードに出しているコメントの種類
    func shownKinds(thanksMessage: DashboardThanksMessage?) -> [EncouragementCommentAnalyticsKind] {
        var kinds: [EncouragementCommentAnalyticsKind] = []
        if let comment = encouragementCommentStore.comment {
            kinds.append(analyticsKind(of: comment))
        }
        switch thanksMessage {
        case .thanksPrompt:
            kinds.append(.thanksPrompt)

        case .receivedThanks:
            kinds.append(.receivedThanks)

        case nil:
            break
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
