//
//  PreviewEnvironment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

extension TimeZone {
    // swiftlint:disable:next force_unwrapping
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
}

extension Locale {
    static let ja = Locale(identifier: "ja_JP")
}

extension View {
    func setupEnvironmentForPreview() -> some View {
        self
            .environment(\.locale, .ja)
            .environment(\.timeZone, .tokyo)
    }
}
