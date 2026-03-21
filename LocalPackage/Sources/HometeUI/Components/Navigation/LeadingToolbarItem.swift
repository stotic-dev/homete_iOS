//
//  LeadingToolbarItem.swift
//  homete
//

import SwiftUI

struct LeadingToolbarModifier<ToolbarContent: View>: ViewModifier {

    let content: () -> ToolbarContent

    func body(content: Content) -> some View {
        #if os(iOS)
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                self.content()
            }
        }
        #else
        content
        #endif
    }
}

public extension View {

    func leadingToolbarItem<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(LeadingToolbarModifier(content: content))
    }
}
