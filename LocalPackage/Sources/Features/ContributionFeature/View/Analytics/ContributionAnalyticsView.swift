//
//  ContributionAnalyticsView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import HometeUI
import SwiftUI

struct ContributionAnalyticsView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale

    @Binding var selectedPeriod: DisplayPointPeriod
    let analytics: ContributionAnalytics?

    var body: some View {
        ScrollView {
            VStack(spacing: .space16) {
                periodTypePicker
                    .padding(.horizontal, .space16)
                periodNavigationHeader
                    .padding(.horizontal, .space16)
                if let currentList = analytics?.currentList(calendar: calendar) {
                    PointsTimeSeriesChartView(viewableData: currentList)
                        .frame(height: 240)
                        .padding(.horizontal, .space16)
                } else {
                    // TODO: データがない旨の空表示を実装する
                }
            }
            .padding(.top, .space16)
        }
    }

    private var periodTypePicker: some View {
        Picker("表示期間", selection: periodTypeBinding) {
            Text("週").tag(DisplayPointPeriod.PeriodType.week)
            Text("月").tag(DisplayPointPeriod.PeriodType.month)
            Text("年").tag(DisplayPointPeriod.PeriodType.year)
        }
        .pickerStyle(.segmented)
    }

    private var periodNavigationHeader: some View {
        HStack {
            Button {
                tappedShiftLeftButton()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.onSurface)
            }
            Spacer()
            Text(periodTitle)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
            Button {
                tappedShiftRightButton()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.onSurface)
            }
        }
    }

    private var periodTypeBinding: Binding<DisplayPointPeriod.PeriodType> {
        Binding(
            get: { selectedPeriod.type },
            set: { selectedPeriod = .init(type: $0, anchor: selectedPeriod.anchor) }
        )
    }

    private var periodTitle: String {
        guard let dateRange = selectedPeriod.calcDateRange(calendar: calendar) else { return "" }
        let dateFormatStyle: Date.FormatStyle
        switch selectedPeriod.type {
        case .week:
            dateFormatStyle = .dateTime.month(.defaultDigits).day().locale(locale)
            
        case .month:
            dateFormatStyle = .dateTime.month(.defaultDigits).day().locale(locale)
            
        case .year:
            dateFormatStyle = .dateTime.year().month(.defaultDigits).locale(locale)
        }
        
        let start = dateRange.lowerBound.formatted(dateFormatStyle)
        let end = dateRange.upperBound.formatted(dateFormatStyle)
        return "\(start) 〜 \(end)"
    }
}

private extension ContributionAnalyticsView {
    
    func tappedShiftLeftButton() {
        
        selectedPeriod = selectedPeriod.shiftPeriod(by: -1, calendar: calendar)
    }
    
    func tappedShiftRightButton() {
        
        selectedPeriod = selectedPeriod.shiftPeriod(by: 1, calendar: calendar)
    }
}

#Preview("ContributionAnalyticsView_週間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod: DisplayPointPeriod = .init(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .week)
    )
    .setupEnvironmentForPreview()
}
