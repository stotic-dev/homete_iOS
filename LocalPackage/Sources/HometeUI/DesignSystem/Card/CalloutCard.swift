//
//  CalloutCard.swift
//  LocalPackage
//

import HometeModel
import HometeResources
import SwiftUI

/// 背景で囲んで目立たせる案内と、その先へ進むボタンのカード
///
/// 画面の主役（カレンダーや一覧など）の下に置いても埋もれさせたくない案内に使う。
/// プレミアムプランへの誘導のように、案内を読んだ人がそのまま次の画面へ進める形にする。
public struct CalloutCard: View {

    let message: LocalizedStringResource
    let systemImage: String
    let actionTitle: LocalizedStringResource
    let action: () -> Void

    /// - Parameters:
    ///   - message: 案内の文言
    ///   - systemImage: 文言の先頭に添えるSF Symbolの名前
    ///   - actionTitle: ボタンの文言
    ///   - action: ボタンをタップしたときの処理
    public init(
        _ message: LocalizedStringResource,
        systemImage: String,
        actionTitle: LocalizedStringResource,
        action: @escaping () -> Void
    ) {
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Label {
                Text(message)
                    .font(with: .boldCaption)
                    .foregroundStyle(.textPrimary)
            } icon: {
                Image(systemName: systemImage)
                    .font(with: .caption)
                    .foregroundStyle(.textAccent)
            }
            Button(actionTitle, action: action)
                .font(with: .boldCaption)
        }
        .padding(.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(radius: .radius12)
                .fill(.fillAccentSubtle)
        }
    }

}

#Preview("CalloutCard", traits: .sizeThatFitsLayout) {
    CalloutCard(
        "この機能は、プレミアムプランで使えます",
        systemImage: "lock.fill",
        actionTitle: .localized("プレミアムプランを見る"),
        action: {}
    )
    .padding(.space16)
}
