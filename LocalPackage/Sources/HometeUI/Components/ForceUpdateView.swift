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
        // この画面は閉じられないため、大きな文字で画面に収まらなくてもボタンまでたどり着けるよう、
        // ボタンも本文と同じ並びに置いて丸ごとスクロールさせる
        ScrollView {
            VStack(spacing: .space16) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.decorativeIcon)
                    .accessibilityHidden(true)
                Text("新しいバージョンがあります", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("引き続き\(Constants.appName)をご利用いただくには、App Storeからアップデートをお願いします。", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                Button {
                    onTapUpdateButton()
                } label: {
                    Text("アップデートする", bundle: #bundle)
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                .padding(.top, .space16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.top, .space48)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
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
