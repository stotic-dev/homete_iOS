//
//  SubscriptionManagementScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 設定の外から、契約プラン画面を単独で出すための画面
///
/// 契約中の人がPaywallを開いたときに、プランの一覧の代わりに出す（`PaywallGate`）
public struct SubscriptionManagementScreen: View {

    let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            SubscriptionManagementView()
                .leadingToolbarItem {
                    NavigationBarButton(label: .close) {
                        onClose()
                    }
                }
        }
    }

}
