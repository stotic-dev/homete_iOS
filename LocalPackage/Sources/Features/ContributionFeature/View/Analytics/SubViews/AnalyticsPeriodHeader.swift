//
//  AnalyticsPeriodHeader.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import SwiftUI

struct AnalyticsPeriodHeader: View {
    
    @Environment(\.locale) var locale
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    
    @Binding var selectedPeriod: DisplayPointPeriod
    
    var body: some View {
        VStack(spacing: .space16) {
            periodTypePicker()
            periodNavigationHeader()
        }
    }
}

private extension AnalyticsPeriodHeader {
    
    func periodTypePicker() -> some View {
        Picker("表示期間", selection: $selectedPeriod.type) {
            Text("週").tag(DisplayPointPeriod.PeriodType.week)
            Text("月").tag(DisplayPointPeriod.PeriodType.month)
            Text("年").tag(DisplayPointPeriod.PeriodType.year)
        }
        .pickerStyle(.segmented)
    }

    func periodNavigationHeader() -> some View {
        HStack {
            Button {
                tappedShiftLeftButton()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.onSurface)
                    .padding(.space8)
            }
            Spacer()
            Text(periodTitle())
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
            Button {
                tappedShiftRightButton()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.onSurface)
                    .padding(.space8)
            }
        }
    }
    
    func periodTitle() -> String {
        
        guard !calendar.isDate(selectedPeriod.anchor, inSameDayAs: now) else {
            
            // 基準日が今日の場合は直近の表示にする
            return switch selectedPeriod.type {
            case .week: "直近1週間"
            case .month: "直近1ヶ月"
            case .year: "直近1年"
            }
        }
        
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

// MARK: プレゼンテーションロジック

private extension AnalyticsPeriodHeader {
    
    func tappedShiftLeftButton() {
        
        selectedPeriod = selectedPeriod.shiftPeriod(by: -1, calendar: calendar)
    }
    
    func tappedShiftRightButton() {
        
        selectedPeriod = selectedPeriod.shiftPeriod(by: 1, calendar: calendar)
    }
}

#Preview("AnalyticsPeriodHeader_直近1週間の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}

#Preview("AnalyticsPeriodHeader_直近1ヶ月の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}

#Preview("AnalyticsPeriodHeader_直近1年の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .year,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}

#Preview("AnalyticsPeriodHeader_直近でない1週間の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 3, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}

#Preview("AnalyticsPeriodHeader_直近でない1ヶ月の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 3, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}

#Preview("AnalyticsPeriodHeader_直近でない1年の表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .year,
        anchor: .previewDate(year: 2026, month: 3, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
}
