//
//  PreviewEnvironment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

#if canImport(UIKit)
import SwiftUI

public extension TimeZone {
    // swiftlint:disable:next force_unwrapping
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
}

public extension Locale {
    static let ja = Locale(identifier: "ja_JP")
}

public extension View {
    func setupEnvironmentForPreview() -> some View {
        self
            .environment(\.locale, .ja)
            .environment(\.timeZone, .tokyo)
    }
}
#endif
