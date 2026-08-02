//
//  FullScreenCoverOnIOS.swift
//  homete
//

import SwiftUI

public extension View {

    func fullScreenCoverOnIOS(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
        #else
        self
        #endif
    }

}
