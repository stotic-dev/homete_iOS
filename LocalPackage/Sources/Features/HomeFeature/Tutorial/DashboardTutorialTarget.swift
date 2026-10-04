//
//  DashboardTutorialTarget.swift
//  LocalPackage
//

import HometeUI

/// ダッシュボードのうち、チュートリアルでハイライトするUI
public extension TutorialSpotlightID {

    /// 今日の家事の達成率
    static let dashboardTodayProgress = Self("dashboard_today_progress")
    /// 今日の家事の、メンバーごとの割合グラフ
    static let dashboardTodayContribution = Self("dashboard_today_contribution")

}
