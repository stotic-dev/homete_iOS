//
//  PaywallPlanOptionContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// プラン1つ分の選択肢。価格・課金期間・月あたりの価格・導入オファーを出す
struct PaywallPlanOptionContent: View {

    @Environment(\.locale) var locale

    let package: PurchasePackage
    let isSelected: Bool
    /// 今契約しているプランか。契約中のプランは選べない
    let isSubscribed: Bool
    /// おすすめの印を付けて目立たせるか
    let isRecommended: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: .space16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .textAccent : .textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: .space4) {
                    Text(package.period.displayName)
                        .font(with: .headLineS)
                        .foregroundStyle(.textPrimary)
                    Text(priceText)
                        .font(with: .body)
                        .foregroundStyle(.textPrimary)
                    if let localizedPricePerMonth = package.localizedPricePerMonth {
                        Text("1か月あたり\(localizedPricePerMonth)", bundle: #bundle)
                            .font(with: isRecommended ? .boldCaption : .caption)
                            .foregroundStyle(isRecommended ? .textAccent : .textSecondary)
                    }
                    if let offer = package.introductoryOffer {
                        Text(introductoryOfferText(offer))
                            .font(with: .caption)
                            .foregroundStyle(.textAccent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSubscribed {
                    Text("利用中", bundle: #bundle, comment: "今契約しているプランに付ける印")
                        .font(with: .caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(.space16)
            // おすすめの印と重ならないよう、上を空ける
            .padding(.top, isRecommended ? .space8 : .zero)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
            .overlay {
                RoundedRectangle(radius: .radius20)
                    .strokeBorder(isSelected ? Color.fillAccent : .clear, lineWidth: 2)
            }
            .shadow(color: isSelected ? Color.fillAccent.opacity(0.25) : .clear, radius: 12, y: 4)
            .overlay(alignment: .topLeading) {
                if isRecommended {
                    recommendedBadge
                        .padding(.leading, .space16)
                        .offset(y: -12)
                }
            }
            .scaleEffect(isSelected ? 1 : 0.98)
            .animation(.spring(duration: 0.35, bounce: 0.4), value: isSelected)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isSubscribed)
        .opacity(isSubscribed ? 0.6 : 1)
        .sensoryFeedback(.selection, trigger: isSelected) { _, isSelected in
            isSelected
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

}

// MARK: UI定義

private extension PaywallPlanOptionContent {

    var recommendedBadge: some View {
        Label {
            Text("おすすめ", bundle: #bundle, comment: "年額プランに付ける印")
        } icon: {
            Image(systemName: "sparkles")
        }
        .font(with: .boldCaption)
        .foregroundStyle(.textReward)
        .padding(.horizontal, .space8)
        .padding(.vertical, .space4)
        .background(.fillRewardSubtle)
        .paywallShimmer()
        .clipShape(.capsule)
        .overlay {
            Capsule()
                .strokeBorder(.fillReward, lineWidth: 1)
        }
    }

    var priceText: LocalizedStringResource {
        switch package.period {
        case .monthly:
            .localized("\(package.localizedPrice) / 月", comment: "月額プランの価格")

        case .yearly:
            .localized("\(package.localizedPrice) / 年", comment: "年額プランの価格")

        case .unknown:
            .localized("\(package.localizedPrice)", comment: "期間が分からないプランの価格")
        }
    }

    func introductoryOfferText(_ offer: IntroductoryOffer) -> LocalizedStringResource {
        let totalPeriod = OfferPeriod(value: offer.period.value * offer.numberOfPeriods, unit: offer.period.unit)
        switch offer.paymentMode {
        case .freeTrial:
            return .localized("最初の\(periodText(totalPeriod))は無料", comment: "無料トライアル。期間は「1週間」など")

        case .payUpFront:
            return .localized(
                "最初の\(periodText(totalPeriod))は\(offer.localizedPrice)",
                comment: "最初にまとめて払う割引。期間は「3か月」など"
            )

        case .payAsYouGo:
            return .localized(
                "最初の\(periodText(totalPeriod))は、\(periodText(offer.period))ごとに\(offer.localizedPrice)",
                comment: "期間ごとに払う割引。期間は「3か月」「1か月」など"
            )
        }
    }

    /// 「1週間」「3か月」のように、表示している言語で期間を書く
    func periodText(_ period: OfferPeriod) -> String {
        var components = DateComponents()
        switch period.unit {
        case .day:
            components.day = period.value

        case .week:
            components.weekOfMonth = period.value

        case .month:
            components.month = period.value

        case .year:
            components.year = period.value
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        return formatter.string(from: components) ?? ""
    }

}

// MARK: Preview定義

#Preview("PaywallPlanOptionContent_年額_選択中", traits: .sizeThatFitsLayout) {
    PaywallPlanOptionContent(
        package: .yearlyForPreview,
        isSelected: true,
        isSubscribed: false,
        isRecommended: true,
        onTap: {}
    )
    .padding()
    .background(.backgroundScreen)
}

#Preview("PaywallPlanOptionContent_月額_無料トライアル", traits: .sizeThatFitsLayout) {
    PaywallPlanOptionContent(
        package: .monthlyWithTrialForPreview,
        isSelected: false,
        isSubscribed: false,
        isRecommended: false,
        onTap: {}
    )
    .padding()
    .background(.backgroundScreen)
}

#Preview("PaywallPlanOptionContent_月額_利用中", traits: .sizeThatFitsLayout) {
    PaywallPlanOptionContent(
        package: .monthlyForPreview,
        isSelected: false,
        isSubscribed: true,
        isRecommended: false,
        onTap: {}
    )
    .padding()
    .background(.backgroundScreen)
}
