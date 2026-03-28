//
//  FullScreenCoverOnIOS.swift
//  homete
//

import SwiftUI

public extension View {

    func fullScreenCoverOnIOS<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #else
        self
        #endif
    }
}
