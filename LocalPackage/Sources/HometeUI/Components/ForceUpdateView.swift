//
//  ForceUpdateView.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 最低バージョンを下回ったときに表示する、閉じられないアップデート案内画面
public struct ForceUpdateView: View {

    @Environment(\.openURL) var openURL

    /// Remote Configで配信された案内文言。`nil`ならアプリ内の文言を表示する
    let message: String?

    public init(message: String?) {
        self.message = message
    }

    public var body: some View {
        // 配信される本文の長さは読めず、この画面は閉じられないため、
        // 本文はスクロールさせ、ボタンは常に押せるよう下端に固定する
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
                Text(message ?? "引き続き\(Constants.appName)をご利用いただくには、App Storeからアップデートをお願いします。")
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

#Preview("ForceUpdateView_アプリ内の文言") {
    ForceUpdateView(message: nil)
}

#Preview("ForceUpdateView_配信された文言") {
    ForceUpdateView(message: "大切なお知らせがあります。データを正しく保存するため、最新のバージョンへのアップデートをお願いします。")
}

#Preview("ForceUpdateView_長い文言_大きな文字") {
    ForceUpdateView(
        message: "大切なお知らせがあります。このバージョンには、家事の記録が正しく保存されない不具合があります。"
            + "データを守るため、最新のバージョンへのアップデートをお願いします。"
            + "アップデートしても、これまでの家事の記録やグループの設定はそのまま引き継がれます。"
    )
    .environment(\.dynamicTypeSize, .accessibility3)
}
