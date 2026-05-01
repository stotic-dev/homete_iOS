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
        Picker("表示期間", selection: $selectedPeriod) {
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
            }
        }
    }
    
    func periodTitle() -> String {
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

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
        .setupEnvironmentForPreview()
}
