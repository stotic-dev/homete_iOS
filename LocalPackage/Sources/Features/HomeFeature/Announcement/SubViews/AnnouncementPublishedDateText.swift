//
//  AnnouncementPublishedDateText.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// お知らせの公開日
///
/// 一覧・詳細・起動時のシートで同じ書式で出すため、ここにまとめる。
struct AnnouncementPublishedDateText: View {

    @Environment(\.locale) var locale
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone

    let date: Date

    var body: some View {
        Text(date, format: Date.FormatStyle(
            date: .abbreviated,
            time: .omitted,
            locale: locale,
            calendar: calendar,
            timeZone: timeZone
        ))
        .font(with: .caption)
        .foregroundStyle(.textSecondary)
    }

}
