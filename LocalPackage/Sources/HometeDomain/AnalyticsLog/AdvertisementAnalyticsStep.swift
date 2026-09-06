//
//  AdvertisementAnalyticsStep.swift
//  LocalPackage
//

/// 広告に関する行動の掲載面
public enum AdvertisementAnalyticsStep: String, Equatable, Sendable {

    /// ダッシュボード上部のバナー
    case dashboard
    /// 家事分析画面下部のバナー
    case contributionAnalytics = "contribution_analytics"
    /// 家事テンプレート画面下部のバナー
    case template

}
