//
//  HideNavigationBarModifier.swift
//  homete
//

import SwiftUI

public extension View {

    func hideNavigationBar() -> some View {
        self.automaticToolbarVisibility(visibility: .hidden, for: .navigationBar)
    }
}
