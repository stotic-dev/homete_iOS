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
        self
            .environment(\.locale, .jp)
            .environment(\.timeZone, .tokyo)
            .environment(\.calendar, .japanese)
    }
}

#endif
