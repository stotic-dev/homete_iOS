//
//  PaywallScreen.swift
//  LocalPackage
//

#if os(iOS)
import RevenueCatUI
import SwiftUI

public struct PaywallScreen: View {

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        PaywallView(displayCloseButton: true)
            .onRequestedDismissal {
                dismiss()
            }
    }

}
#endif
