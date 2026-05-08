//
//  AllUserDataAnnotation.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/07.
//

import SwiftUI

struct AllUserDataAnnotation: View {
    
    @Environment(\.timeZone) var timeZone
    @Environment(\.locale) var locale
    
    let entries: [PointEntry]
    let selectedDate: Date
    let displayPeriod: DisplayPointPeriod.PeriodType
    
    var body: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text(selectedDate, format: titleDateFormat)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)
            if entries.isEmpty {
                Text("データ無し")
                    .font(with: .boldCaption)
            } else {
                ForEach(entries) { entry in
                    Text("\(entry.userName): \(entry.point)pt")
                        .font(with: .boldCaption)
                }
            }
        }
        .padding(.horizontal, .space8)
        .padding(.vertical, .space4)
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

private extension AllUserDataAnnotation {
    
    var titleDateFormat: Date.FormatStyle {
        var style: Date.FormatStyle
        switch displayPeriod {
        case .year: style = .dateTime.year().month().locale(locale)
        case .month, .week: style = .dateTime.month().day().locale(locale)
        }
        style.timeZone = timeZone
        return style
    }
}

#Preview("AllUserDataAnnotation_データ有り", traits: .sizeThatFitsLayout) {
    AllUserDataAnnotation(
       entries: [
        .init(id: "1", userName: "佐藤", point: 20),
        .init(id: "2", userName: "佐藤2", point: 1000000)
       ],
       selectedDate: .previewDate(year: 2026, month: 1, day: 1),
       displayPeriod: .week
    )
    .setupEnvironmentForPreview()
    .padding(.space16)
}

#Preview("AllUserDataAnnotation_データ無し", traits: .sizeThatFitsLayout) {
    AllUserDataAnnotation(
       entries: [],
       selectedDate: .previewDate(year: 2026, month: 1, day: 1),
       displayPeriod: .week
    )
    .setupEnvironmentForPreview()
    .padding(.space16)
}

