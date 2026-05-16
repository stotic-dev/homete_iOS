//
//  PreviewEnvironment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

#if DEBUG

    public extension View {

        func setupEnvironmentForPreview() -> some View {
            var calendar = Calendar.japanese
            calendar.timeZone = .tokyo
            return environment(\.locale, .jp)
                .environment(\.timeZone, .tokyo)
                .environment(\.calendar, calendar)
        }

    }

#endif
