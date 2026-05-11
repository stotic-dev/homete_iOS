//
//  InlineNavigationBarTitleDisplayMode.swift
//  homete
//

import SwiftUI

public extension View {

    func inlineNavigationBarTitleDisplayMode() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

}
