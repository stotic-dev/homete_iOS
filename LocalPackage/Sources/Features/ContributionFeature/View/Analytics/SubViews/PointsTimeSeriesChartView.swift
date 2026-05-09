//
//  PointsTimeSeriesChartView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import Charts
import HometeDomain
import HometeUI
import SwiftUI

struct PointsTimeSeriesChartView: View {

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    
    let viewableData: AllUserViewablePointList
    
    @State var selectedDate: Date?

    var body: some View {
        VStack(spacing: .space16) {
            HStack(spacing: .zero) {
                Text("\(periodUnitLabel)獲得ポイント")
                    .font(with: .headLineS)
                Spacer()
                GraphDescriptionPopoverButton(
                    title: "獲得ポイントからわかること",
                    message: """
                        期間中、\(periodUnitLabel)に獲得したポイントを表します。
                        同じ日のユーザー同士を比較すれば、その日に誰がよく頑張ったかが一目でわかります。
                        """
                )
            }
            graphContent(viewableData.list)
        }
    }
}

// MARK: UI定義

private extension PointsTimeSeriesChartView {
    
    func graphContent(_ list: [ViewablePointList]) -> some View {
        Chart {
            ForEach(list, id: \.self) { userData in
                userDataPlotContent(userData)
            }
            if let date = selectedDate {
                selectedChartMark(date)
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, position: .bottom, values: xAxisStride) { _ in
                AxisValueLabel(
                    format: xLabelFormat,
                    multiLabelAlignment: .leading
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
    
    func userDataPlotContent(_ userData: ViewablePointList) -> some ChartContent {
        ForEach(userData.sortedElements, id: \.self) { element in
            LineMark(
                x: .value("日付", element.date),
                y: .value("ポイント", element.point.value)
            )
            .foregroundStyle(by: .value("ユーザー", userData.userName))
            PointMark(
                x: .value("日付", element.date),
                y: .value("ポイント", element.point.value)
            )
            .foregroundStyle(by: .value("ユーザー", userData.userName))
        }
    }
    
    func selectedChartMark(_ selectedDate: Date) -> some ChartContent {
        RuleMark(x: .value("日付", selectedDate))
            .foregroundStyle(.secondary.opacity(0.3))
            .annotation(
                position: .top,
                alignment: .center,
                overflowResolution: .init(
                    x: .fit(to: .chart),
                    y: .disabled
                )
            ) {
                AllUserDataAnnotation(
                    entries: viewableData.pointEntries(for: selectedDate, calendar: calendar),
                    selectedDate: selectedDate,
                    displayPeriod: viewableData.displayPeriod
                )
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
        var style: Date.FormatStyle
        switch viewableData.displayPeriod {
        case .year: style = .dateTime.month(.defaultDigits).locale(locale)
        case .month: style = .dateTime.day().locale(locale)
        case .week: style = .dateTime.weekday(.abbreviated).locale(locale)
        }
        style.timeZone = timeZone
        return style
    }
    
    var periodUnitLabel: String {
        return switch viewableData.displayPeriod {
        case .year: "月ごとの"
        case .month, .week: "日ごとの"
        }
    }
}

// MARK: プレゼンテーションロジック

private extension PointsTimeSeriesChartView {
    
    func handleTap(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        
        let frame = geometry.frame(in: .local)
        guard let tapDate: Date = proxy.value(atX: location.x - frame.minX) else { return }
        guard let nearest = viewableData.nearestDate(to: tapDate) else {
            selectedDate = nil
            return
        }
        selectedDate = selectedDate == nearest ? nil : nearest
    }
}

#Preview("PointsTimeSeriesChartView_週間 (日別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .week)
        .currentList(calendar: .japanese)

    PointsTimeSeriesChartView(
        viewableData: allUserList,
        selectedDate: .previewDate(year: 2026, month: 4, day: 24)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.horizontal, .space16)
    .padding(.vertical, .space56)
}

#Preview("PointsTimeSeriesChartView_月間 (日別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .month)
        .currentList(calendar: .japanese)

    PointsTimeSeriesChartView(
        viewableData: allUserList,
        selectedDate: .previewDate(year: 2026, month: 4, day: 24)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.horizontal, .space16)
    .padding(.vertical, .space56)
    // Xcode Cloudでわずかに差分が出てしまうので必要とする一致率を下げる
    .snapshotForPreview(precision: 0.95, perceptualPrecision: 0.95)
}

#Preview("PointsTimeSeriesChartView_年間 (月別)", traits: .sizeThatFitsLayout) {
    let allUserList = ContributionAnalytics
        .makeForPreview(type: .year)
        .currentList(calendar: .japanese)

    PointsTimeSeriesChartView(
        viewableData: allUserList,
        selectedDate: .previewDate(year: 2026, month: 4, day: 1)
    )
    .frame(height: 240)
    .setupEnvironmentForPreview()
    .padding(.horizontal, .space16)
    .padding(.vertical, .space56)
}
