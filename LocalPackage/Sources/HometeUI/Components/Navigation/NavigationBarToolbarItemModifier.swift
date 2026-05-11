//
//  NavigationBarToolbarItemModifier.swift
//  homete
//

import SwiftUI

struct NavigationBarToolbarItemModifier<ToolbarContent: View>: ViewModifier {

    enum Position {

        case leading, trailing

    }

    let position: Position
    let content: () -> ToolbarContent

    func body(content: Content) -> some View {
        #if os(iOS)
            content.toolbar {
                ToolbarItem(placement: position == .leading ? .topBarLeading : .topBarTrailing) {
                    self.content()
                }
            }
        #else
            content
        #endif
    }

}

public extension View {

    func trailingToolbarItem(
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(NavigationBarToolbarItemModifier(position: .trailing, content: content))
    }

    func leadingToolbarItem(
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(NavigationBarToolbarItemModifier(position: .leading, content: content))
    }

}
