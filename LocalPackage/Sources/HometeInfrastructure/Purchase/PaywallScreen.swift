//
//  PaywallScreen.swift
//  LocalPackage
//

#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif
import SwiftUI

public struct PaywallScreen: View {

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        #if canImport(RevenueCatUI)
        if Purchases.isConfigured {
            PaywallView(displayCloseButton: true)
                .onRequestedDismissal {
                    dismiss()
                }
        } else {
            unavailableContent
        }
        #else
        unavailableContent
        #endif
    }

}

private extension PaywallScreen {

    var unavailableContent: some View {
        VStack(spacing: 16) {
            Text("現在プレミアムプランをご利用いただけません")
            Button("閉じる") {
                dismiss()
            }
        }
        .padding()
    }

}
