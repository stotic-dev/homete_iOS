//
//  ForceUpdateView.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 最低バージョンを下回ったときに表示する、閉じられないアップデート案内画面
public struct ForceUpdateView: View {

    @Environment(\.openURL) var openURL

    public init() {}

    public var body: some View {
        // この画面は閉じられないため、大きな文字でも本文はスクロールさせ、ボタンは常に押せるよう下端に固定する
        ScrollView {
            VStack(spacing: .space16) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.decorativeIcon)
                    .accessibilityHidden(true)
                Text("新しいバージョンがあります")
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("引き続き\(Constants.appName)をご利用いただくには、App Storeからアップデートをお願いします。")
                    .font(with: .body)
                    .foregroundStyle(.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.top, .space48)
            .padding(.bottom, .space24)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onTapUpdateButton()
            } label: {
                Text("アップデートする")
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
        }
        .trackScreenView(.forceUpdate)
    }

}

private extension ForceUpdateView {

    func onTapUpdateButton() {
        guard let url = URL(string: Constants.appStoreURLString) else { return }
        openURL(url)
    }

}

#Preview("ForceUpdateView") {
    ForceUpdateView()
}

#Preview("ForceUpdateView_大きな文字") {
    ForceUpdateView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
