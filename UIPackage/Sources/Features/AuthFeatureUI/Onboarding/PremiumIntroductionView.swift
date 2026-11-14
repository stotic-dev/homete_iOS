//
//  PremiumIntroductionView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// オンボーディングでプレミアムプランの特典を説明し、Paywallへの導線を提供する画面
/// - Note: Paywallの表示と計測は`PremiumIntroductionScreen`が受け持つ
public struct PremiumIntroductionView: View {

    let onTapShowPaywall: () -> Void
    let onTapSkip: () -> Void

    public init(onTapShowPaywall: @escaping () -> Void, onTapSkip: @escaping () -> Void) {
        self.onTapShowPaywall = onTapShowPaywall
        self.onTapSkip = onTapSkip
    }

    public var body: some View {
        VStack(spacing: .space32) {
            VStack(spacing: .space16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.iconDecorative)
                Text("プレミアムプランのご案内", bundle: #bundle)
                    .font(with: .headLineM)
                Text("homeauは無料のままでもすべての家事管理機能をお使いいただけます。\nもっと快適に使いたい方向けに、プレミアムプランをご用意しています。", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: .space24) {
                benefitRow(
                    systemImage: "rectangle.slash",
                    title: .localized("広告が表示されません"),
                    description: .localized("ダッシュボードのバナー広告が消え、家事の記録に集中できます。")
                )
                benefitRow(
                    systemImage: "sparkles",
                    title: .localized("今後追加される機能もすべて使えます"),
                    description: .localized("プレミアム限定の新機能が増えても、追加の料金はかかりません。")
                )
            }
            Spacer(minLength: .space24)
            VStack(spacing: .space16) {
                Button {
                    onTapShowPaywall()
                } label: {
                    Text("プランを見る", bundle: #bundle)
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                Button(.localized("あとで決める")) {
                    onTapSkip()
                }
                .font(with: .body)
                .foregroundStyle(.textSecondary)
            }
            Spacer()
                .frame(height: .space24)
        }
        .padding(.horizontal, .space16)
        .padding(.top, .space32)
        .frame(maxHeight: .infinity, alignment: .top)
    }

}

// MARK: UI定義

private extension PremiumIntroductionView {

    func benefitRow(
        systemImage: String,
        title: LocalizedStringResource,
        description: LocalizedStringResource
    ) -> some View {
        HStack(alignment: .top, spacing: .space16) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.iconDecorative)
                .frame(width: .space32)
            VStack(alignment: .leading, spacing: .space4) {
                Text(title)
                    .font(with: .headLineS)
                Text(description)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}

#Preview("PremiumIntroductionView") {
    PremiumIntroductionView(onTapShowPaywall: {}, onTapSkip: {})
}
