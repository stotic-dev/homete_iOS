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
        Chart {
            ForEach(viewableData.list, id: \.self) { userData in
                userCumulativeArea(userData)
            }
            if let date = selectedDate {
                RuleMark(x: .value("日付", date))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .annotation(
                        position: .top,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        AllUserDataAnnotation(
                            entries: viewableData.cumulativePointEntries(
                                for: date,
                                calendar: calendar
                            ),
                            selectedDate: date,
                            displayPeriod: viewableData.displayPeriod
                        )
                    }
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
}

// MARK: UI定義

private extension CumulativePointsAreaChartView {
    
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
    
    var xAxisStride: AxisMarkValues {
        switch viewableData.displayPeriod {
        case .week:
            return .automatic(desiredCount: 7)
        case .month:
            return .automatic(desiredCount: 5)
        case .year:
            return .automatic(desiredCount: 12)
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

#Preview("CumulativePointsAreaChartView_週間 (日別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .week)
        .currentList(calendar: .japanese)

    CumulativePointsAreaChartView(
        viewableData: AllUserCumulativeData.make(
            list: allUserList?.list ?? [],
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
            list: allUserList?.list ?? [],
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
            list: allUserList?.list ?? [],
            displayPeriod: .year
        )
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.space16)
}
