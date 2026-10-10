//
//  FrequentHouseworkImportScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// テンプレートの家事をいつもの家事に取り込むシート
/// - Note: 管理画面の「⋯」と空状態から開く
struct FrequentHouseworkImportScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.frequentHouseworkContext) var context
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.routeResolver) var router
    @Environment(FrequentHouseworkStore.self) var store: FrequentHouseworkStore?
    @Environment(SubscriptionStore.self) var subscriptionStore

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var selection = FrequentHouseworkImportSelection()
    @State var isPresentingLimitAlert = false
    @State var isShowPaywall = false

    var body: some View {
        FrequentHouseworkImportView(
            candidates: candidates,
            checkedTitles: selection.checkedTitles(in: candidates),
            importCount: selection.selectedCount,
            onTapClose: { dismiss() },
            onTapCandidate: { candidate in tappedCandidate(candidate) },
            onTapImport: { tappedImportButton() }
        )
        .alert(
            .localized("無料プランでは、いつもの家事を\(FrequentHouseworkLimitPolicy.freeLimit)件まで登録できます"),
            isPresented: $isPresentingLimitAlert
        ) {
            Button(.localized("プレミアムプランを見る")) {
                showPaywall()
            }
            Button(.localized("閉じる"), role: .cancel) {}
        } message: {
            Text("プレミアムプランにすると、件数を気にせず登録できます。", bundle: #bundle)
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
    }

}

// MARK: - 表示内容

private extension FrequentHouseworkImportScreen {

    /// テンプレートの全曜日から集めた、名前で重複を除いた候補
    var candidates: [FrequentHouseworkImportCandidate] {
        context.importCandidates(from: templateContext.houseworkTemplate)
    }

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

}

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkImportScreen {

    func tappedCandidate(_ candidate: FrequentHouseworkImportCandidate) {
        let remainingCount = limitPolicy.remainingCount(currentCount: context.items.count)
        switch selection.toggling(candidate, remainingCount: remainingCount) {
        case let .changed(newSelection):
            selection = newSelection

        case .limitReached:
            store?.logLimitReached(step: .management)
            isPresentingLimitAlert = true

        case .unavailable:
            break
        }
    }

    func tappedImportButton() {
        // 読み込み前・リスナーが止まった後の一覧で判定すると、件数上限や名前の重複をすり抜けてしまう
        guard let store, store.loadState == .loaded, let cohabitantId else { return }
        let targets = selection.importTargets(from: candidates)
        guard !targets.isEmpty else { return }
        loadingState.task {
            do {
                try await store.importFromTemplate(targets, limitPolicy: limitPolicy, cohabitantId: cohabitantId)
                dismiss()
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    func showPaywall() {
        analyticsClient.log(.paywall(.shown(step: .frequentHouseworkLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(
            step: .frequentHouseworkLimit,
            isPremium: subscriptionStore.isPremium
        )))
    }

}
