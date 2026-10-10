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
struct DashboardContent<TodaySummary: View, Advertisement: View, ContributionSummary: View>: View {

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
    @ViewBuilder let todaySummary: () -> TodaySummary
    @ViewBuilder let advertisement: () -> Advertisement
    @ViewBuilder let contributionSummary: () -> ContributionSummary

    var body: some View {
        ZStack {
            if let loadFailure {
                LoadErrorView(error: loadFailure, onTapRetry: onTapRetry)
            } else {
                ScrollView {
                    VStack(spacing: .space24) {
                        todaySummary()
                            .sectionCardStyle()
                            // カードの背景ごと切り抜くため、見た目を付けた後に付ける
                            .tutorialSpotlightTarget(.dashboardTodaySummary)
                        if showsAdvertisement {
                            VStack(spacing: .space8) {
                                advertisement()
                                    .frame(height: 150)
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
                    }
                    .padding(.horizontal, .space16)
                    .padding(.vertical, .space16)
                }
            }
        }
    }

}
