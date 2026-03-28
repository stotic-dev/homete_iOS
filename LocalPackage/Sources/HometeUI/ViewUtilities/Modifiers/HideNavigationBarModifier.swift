//
//  HideNavigationBarModifier.swift
//  homete
//

import SwiftUI

public extension View {

    func hideNavigationBar() -> some View {
        #if os(iOS)
        self.automaticToolbarVisibility(visibility: .hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}
