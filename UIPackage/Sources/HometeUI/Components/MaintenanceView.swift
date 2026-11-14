//
//  MaintenanceView.swift
//  LocalPackage
//

import HometeModel
import SwiftUI

/// Remote Configでアプリ全体を止めているときに表示する、閉じられないメンテナンス画面
///
/// 操作できるものは置かない。メンテナンスを終えると、リアルタイム更新か復帰時の取得で自動的に元の画面へ戻る。
public struct MaintenanceView: View {

    public init() {}

    public var body: some View {
        // 大きな文字で画面に収まらなくても読み切れるよう、丸ごとスクロールさせる
        ScrollView {
            VStack(spacing: .space16) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.iconDecorative)
                    .accessibilityHidden(true)
                Text("ただいまメンテナンス中です", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("ご不便をおかけして申し訳ありません。終わりしだい使えるようになりますので、しばらくお待ちください。", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.top, .space48)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

}

#Preview("MaintenanceView") {
    MaintenanceView()
}

#Preview("MaintenanceView_大きな文字") {
    MaintenanceView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
