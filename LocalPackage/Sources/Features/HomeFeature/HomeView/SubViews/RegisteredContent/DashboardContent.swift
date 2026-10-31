//
//  DashboardContent.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

/// ダッシュボード（グループ登録済み）のUI
///
/// セクションの並びと見た目だけを持ち、各セクションの中身は呼び出し側から受け取る。
/// 本番ではStoreにつながったセクションを、チュートリアルではサンプルを渡したセクションを並べることで、
/// レイアウトの変更がチュートリアルにもそのまま反映されるようにする。
struct DashboardContent<
    EncouragementComment: View,
    TodaySummary: View,
    Advertisement: View,
    ContributionSummary: View,
    PastIncomplete: View
>: View {

    /// 購読に失敗している場合のエラー内容
    let loadFailure: DomainError?
    let showsAdvertisement: Bool
    /// 貢献度の集計を読み込んでいる間はプレースホルダで見せる
    let isLoading: Bool
    /// 家事テンプレートが未設定のときに、設定を促すバナーを出す
    let showsTemplateBanner: Bool
    let onTapRetry: () -> Void
    let onTapRemoveAdsPromotion: () -> Void
    let onTapTemplateBanner: () -> Void
    /// ねぎらいのコメントと感謝の促しのカード。出さない場合は`EmptyView`を渡す
    @ViewBuilder let encouragementComment: () -> EncouragementComment
    @ViewBuilder let todaySummary: () -> TodaySummary
    @ViewBuilder let advertisement: () -> Advertisement
    @ViewBuilder let contributionSummary: () -> ContributionSummary
    /// やり残している家事。日付ごとのカードを`LazyVStack`の要素として並べるため、カードの見た目は付けない
    @ViewBuilder let pastIncompleteHousework: () -> PastIncomplete

    var body: some View {
        ZStack {
            if let loadFailure {
                LoadErrorView(error: loadFailure, onTapRetry: onTapRetry)
            } else {
                ScrollView {
                    // やり残している家事は件数に上限が無いため、画面外の行を描画しないよう遅延して並べる
                    LazyVStack(spacing: .space24) {
                        encouragementComment()
                            .sectionCardStyle()
                        todaySummary()
                            .sectionCardStyle()
                            // カードの背景ごと切り抜くため、見た目を付けた後に付ける
                            .tutorialSpotlightTarget(.dashboardTodaySummary)
                        if showsAdvertisement {
                            // AdMobのガイドラインに沿って、誤タップを防ぐためにタップできるリンクを広告から離す
                            VStack(spacing: .space16) {
                                // 高さは届いた広告のサイズから決まる（インライン型アダプティブバナー）
                                advertisement()
                                RemoveAdsPromotionLink(action: onTapRemoveAdsPromotion)
                            }
                        }
                        contributionSummary()
                            .redacted(reason: isLoading ? .placeholder : [])
                            .sectionCardStyle()
                        if showsTemplateBanner {
                            PromoteHouseworkTemplateBanner(action: onTapTemplateBanner)
                                .sectionCardStyle()
                        }
                        pastIncompleteHousework()
                    }
                    .padding(.horizontal, .space16)
                    .padding(.vertical, .space16)
                }
            }
        }
        // 白いカードが浮いて見えるよう、画面の地はミルク色にする
        .background(.backgroundScreen)
    }

}
