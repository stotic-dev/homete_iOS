//
//  PaywallBenefitListContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// プレミアムプランの特典の一覧
struct PaywallBenefitListContent: View {

    let benefits: [PaywallBenefit]

    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text("プレミアムプランでできること", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: .zero) {
                ForEach(Array(benefits.enumerated()), id: \.element) { index, benefit in
                    if index > 0 {
                        // アイコンの右から区切る
                        Divider()
                            .padding(.leading, .space16 + .space40 + .space16)
                    }
                    benefitRow(benefit)
                        .padding(.space16)
                }
            }
            .background(.backgroundCard)
            .cornerRadius(.radius20)
        }
    }

}

// MARK: UI定義

private extension PaywallBenefitListContent {

    func benefitRow(_ benefit: PaywallBenefit) -> some View {
        HStack(alignment: .top, spacing: .space16) {
            Image(systemName: systemImage(benefit))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.textAccent)
                .frame(width: .space40, height: .space40)
                .background(.fillAccentSubtle, in: RoundedRectangle(radius: .radius12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: .space4) {
                Text(title(benefit))
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Text(description(benefit))
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    func systemImage(_ benefit: PaywallBenefit) -> String {
        switch benefit {
        case .noAds:
            "nosign"

        case .unlimitedHistory:
            "clock.arrow.circlepath"

        case .houseworkImage:
            "photo.on.rectangle.angled"

        case .unlimitedFrequentHousework:
            "star.square.on.square"

        case .longerMemo:
            "note.text"
        }
    }

    func title(_ benefit: PaywallBenefit) -> LocalizedStringResource {
        switch benefit {
        case .noAds:
            .localized("広告が表示されません")

        case .unlimitedHistory:
            .localized("すべての記録を振り返れます")

        case .houseworkImage:
            .localized("家事に写真を添えられます")

        case .unlimitedFrequentHousework:
            .localized("いつもの家事を好きなだけ登録できます")

        case .longerMemo:
            .localized("家事メモをたっぷり書けます")
        }
    }

    func description(_ benefit: PaywallBenefit) -> LocalizedStringResource {
        // 「5,000」のように桁区切りを付けて出す
        let freeMemoCharacterCount = HouseworkMemoLimitPolicy.freeMaxCharacterCount.formatted()
        let premiumMemoCharacterCount = HouseworkMemoLimitPolicy.premiumMaxCharacterCount.formatted()
        return switch benefit {
        case .noAds:
            .localized("バナー広告が消えて、画面がすっきりします。")

        case .unlimitedHistory:
            .localized("3か月より前の家事の記録も、いつでも見られます。")

        case .houseworkImage:
            .localized(
                "1つの家事に\(HouseworkImagePolicy.maxImageCount)枚まで。やり方や仕上がりを同居人と共有できます。",
                comment: "数字は1つの家事に添えられる写真の枚数"
            )

        case .unlimitedFrequentHousework:
            .localized(
                "無料プランの\(FrequentHouseworkLimitPolicy.freeLimit)件までという上限がなくなります。",
                comment: "数字は無料プランで登録できるいつもの家事の件数"
            )

        case .longerMemo:
            .localized(
                "メモに書ける文字数が、\(freeMemoCharacterCount)文字から\(premiumMemoCharacterCount)文字に増えます。",
                comment: "無料プランとプレミアムプランで家事メモに書ける文字数"
            )
        }
    }

}

#Preview("PaywallBenefitListContent", traits: .sizeThatFitsLayout) {
    PaywallBenefitListContent(benefits: PaywallBenefit.allCases)
        .padding()
        .background(.backgroundScreen)
}
