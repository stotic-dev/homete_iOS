//
//  TrailingToolbarItem.swift
//  homete
//

import SwiftUI

struct TrailingToolbarModifier<ToolbarContent: View>: ViewModifier {

    let content: () -> ToolbarContent

    func body(content: Content) -> some View {
        #if os(iOS)
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.content()
            }
        }
        #else
        content
        #endif
    }
}

public extension View {

    func trailingToolbarItem<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(TrailingToolbarModifier(content: content))
    }
}
