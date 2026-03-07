//
//  AutomaticToolbarVisibilityModifier.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/31.
//

#if canImport(UIKit)
import SwiftUI

struct AutomaticToolbarVisibilityModifier: ViewModifier {
    
    let visibility: Visibility
    let position: ToolbarPlacement
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .toolbarVisibility(visibility, for: position)
        } else {
            content.toolbar(visibility, for: position)
        }
    }
}

public extension View {

    func automaticToolbarVisibility(
        visibility: Visibility,
        for position: ToolbarPlacement
    ) -> some View {
        self.modifier(AutomaticToolbarVisibilityModifier(
            visibility: visibility,
            position: position)
        )
    }
}
#endif
