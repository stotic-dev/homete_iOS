//
//  ChartStyle.swift
//  LocalPackage
//

import Charts
import HometeResources
import SwiftUI

/// グラフでメンバーを塗り分ける色
///
/// メンバー一覧の順（自分が先頭）に、若葉・はちみつ・もも・空の色を割り当てる。5人目からは先頭の色に戻る。
public enum MemberChartPalette {

    static let colors: [Color] = [.fillAccent, .fillReward, .fillThanks, .fillChartSky]

    /// 並び順が`index`番目のメンバーの色
    public static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }

    /// 先頭から`count`人分の色
    public static func colors(count: Int) -> [Color] {
        (0 ..< count).map(color(at:))
    }

}

public extension View {

    /// グラフの系列をメンバーの色で塗り分ける
    ///
    /// 実績0のメンバーは系列が描かれないため、凡例から漏れないよう全員の名前を渡す。
    /// - Parameter memberNames: メンバー一覧の順（自分が先頭）に並べた名前
    func memberChartForegroundStyle(memberNames: [String]) -> some View {
        chartForegroundStyleScale(domain: memberNames, range: MemberChartPalette.colors(count: memberNames.count))
    }

}

public extension ChartContent {

    /// 折れ線を、角の立たないなめらかな太めの線にする
    ///
    /// 0を下回る山ができないよう、点を通りつつ行き過ぎない補間にする。
    func softLineStyle() -> some ChartContent {
        interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    /// 面グラフの縁を、`softLineStyle()`の折れ線と同じ曲線にする
    func softAreaStyle() -> some ChartContent {
        interpolationMethod(.monotone)
    }

    /// 棒や扇形の角を丸める
    func softCornerStyle() -> some ChartContent {
        cornerRadius(DesignSystem.Corner.radius12.rawValue)
    }

}

#Preview("MemberChartPalette", traits: .sizeThatFitsLayout) {
    let names = ["自分", "はなこ", "じろう", "さぶろう"]
    Chart(Array(names.enumerated()), id: \.offset) { index, name in
        BarMark(
            x: .value("名前", name),
            y: .value("ポイント", (index + 1) * 10)
        )
        .foregroundStyle(by: .value("名前", name))
        .softCornerStyle()
    }
    .memberChartForegroundStyle(memberNames: names)
    .frame(height: 200)
    .padding(.space16)
}
