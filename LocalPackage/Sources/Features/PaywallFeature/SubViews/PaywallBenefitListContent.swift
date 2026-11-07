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
        VStack(spacing: .space24) {
            ForEach(benefits, id: \.self) { benefit in
                benefitRow(benefit)
            }
        }
    }

}

// MARK: UI定義

private extension PaywallBenefitListContent {

    func benefitRow(_ benefit: PaywallBenefit) -> some View {
        HStack(alignment: .top, spacing: .space16) {
            Image(systemName: systemImage(benefit))
                .font(.title3)
                .foregroundStyle(.iconDecorative)
                .frame(width: .space32)
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
            "rectangle.slash"

        case .unlimitedHistory:
            "clock.arrow.circlepath"

        case .houseworkImage:
            "photo.on.rectangle"
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
        }
    }

    func description(_ benefit: PaywallBenefit) -> LocalizedStringResource {
        switch benefit {
        case .noAds:
            .localized("バナー広告が消え、家事の記録に集中できます。")

        case .unlimitedHistory:
            .localized("3か月より前の家事の記録も、いつでも振り返れます。")

        case .houseworkImage:
            .localized("やり方や仕上がりを写真で残して、同居人と共有できます。")
        }
    }

}

#Preview("PaywallBenefitListContent", traits: .sizeThatFitsLayout) {
    PaywallBenefitListContent(benefits: PaywallBenefit.allCases)
        .padding()
}
