//
//  CumulativePointsAreaChartView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/03.
//

import Charts
import HometeUI
import SwiftUI

struct CumulativePointsAreaChartView: View {

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) var timeZone

    @State var selectedDate: Date?

    let viewableData: AllUserCumulativeData

    var body: some View {
        VStack(spacing: .space16) {
            HStack(spacing: .zero) {
                Text(graphTitle)
                    .font(with: .headLineS)
                Spacer()
                GraphDescriptionPopoverButton(
                    title: "獲得ポイントの累積からわかること",
                    message: """
                    期間の最初から日が経つごとに積み上がっていく合計ポイントです。
                    期間の終わりで最も高い位置にいる人が、その期間中にもっとも多くポイントを獲得した人です。
                    線の傾きが急な時期は、その日に多くポイントを獲得した時期を表します。
                    """
                )
            }
            graphContent(viewableData.list)
        }
    }

}

// MARK: UI定義

private extension CumulativePointsAreaChartView {

    func graphContent(_ list: [ViewablePointList]) -> some View {
        Chart {
            ForEach(list, id: \.self) { userData in
                userCumulativeArea(userData)
            }
            if let date = selectedDate {
                selectedChartMark(date)
            }
        }
        .chartXAxis {
            AxisMarks(
                preset: .aligned,
                position: .bottom,
                values: xAxisStride
            ) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(
                    format: xLabelFormat,
                    multiLabelAlignment: .center
                )
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel("\(value.as(Int.self) ?? 0)pt")
            }
        }
        .chartLegend(position: .bottom, alignment: .center)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
    }

    func userCumulativeArea(_ userData: ViewablePointList) -> some ChartContent {
        ForEach(userData.sortedElements, id: \.self) { element in
            AreaMark(
                x: .value("日付", element.date),
                y: .value("累計ポイント", element.point.value)
            )
            .foregroundStyle(by: .value("ユーザー", userData.userName))
            .opacity(0.4)
            LineMark(
                x: .value("日付", element.date),
                y: .value("累計ポイント", element.point.value)
            )
            .foregroundStyle(by: .value("ユーザー", userData.userName))
        }
    }

    func selectedChartMark(_ selectedDate: Date) -> some ChartContent {
        RuleMark(x: .value("日付", selectedDate))
            .foregroundStyle(.secondary.opacity(0.3))
            .annotation(
                position: .top,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                AllUserDataAnnotation(
                    entries: viewableData.cumulativePointEntries(
                        for: selectedDate,
                        calendar: calendar
                    ),
                    selectedDate: selectedDate,
                    displayPeriod: viewableData.displayPeriod
                )
            }
    }

    var xAxisStride: AxisMarkValues {
        switch viewableData.displayPeriod {
        case .week:
            .automatic(desiredCount: 7)
        case .month:
            .automatic(desiredCount: 5)
        case .year:
            .automatic(desiredCount: 12)
        }
    }

    var xLabelFormat: Date.FormatStyle {
        var formatStyle: Date.FormatStyle = switch viewableData.displayPeriod {
        case .year: .dateTime.month(.defaultDigits).locale(locale)
        case .month: .dateTime.day().locale(locale)
        case .week: .dateTime.weekday(.abbreviated).locale(locale)
        }

        formatStyle.timeZone = timeZone
        return formatStyle
    }

    var graphTitle: String {
        let unitStr = switch viewableData.displayPeriod {
        case .year: "月ごと"
        case .month, .week: "日ごと"
        }

        return "\(unitStr)獲得ポイントの累積"
    }

}

// MARK: プレゼンテーションロジック

private extension CumulativePointsAreaChartView {

    func handleTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .local)
        guard let tapDate: Date = proxy.value(atX: location.x - frame.minX) else { return }
        let nearest = viewableData.nearestDate(to: tapDate)
        selectedDate = selectedDate == nearest ? nil : nearest
    }

}

#if DEBUG
#Preview("CumulativePointsAreaChartView_週間 (日別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .week)
        .currentList(calendar: .japanese)

    CumulativePointsAreaChartView(
        viewableData: AllUserCumulativeData.make(
            list: allUserList.list,
            displayPeriod: .week
        )
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("CumulativePointsAreaChartView_月間 (日別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .month)
        .currentList(calendar: .japanese)

    CumulativePointsAreaChartView(
        viewableData: AllUserCumulativeData.make(
            list: allUserList.list,
            displayPeriod: .month
        )
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("CumulativePointsAreaChartView_年間 (月別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .year)
        .currentList(calendar: .japanese)

    CumulativePointsAreaChartView(
        viewableData: AllUserCumulativeData.make(
            list: allUserList.list,
            displayPeriod: .year
        )
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}
#endif
