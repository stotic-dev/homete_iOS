//
//  WelcomeIllustration.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 説明画面の各ページで、そのページで紹介する機能を表す図
///
/// アプリの画面を簡略化したカードで機能を見せ、ほめっとは隅に小さく添える。
/// 家事の名前・メンバーの名前・数値は、機能を伝えるための見本の値。
struct WelcomeIllustration: View {

    let page: WelcomePage

    var body: some View {
        illustration
            .padding(.space16)
            .frame(maxWidth: 320)
            .background {
                RoundedRectangle(radius: .radius20)
                    .fill(.backgroundCard)
            }
            .overlay(alignment: .topTrailing) {
                HometteView(hometteExpression, size: .small)
                    .offset(x: .space8, y: -48)
            }
            .padding(.top, .space32)
            // 見本の値を読み上げても伝わらないため、図は読み上げず、見出しと説明に任せる
            .accessibilityHidden(true)
    }

}

// MARK: UI定義

private extension WelcomeIllustration {

    @ViewBuilder
    var illustration: some View {
        switch page {
        case .record:
            recordIllustration
        case .share:
            shareIllustration
        case .thanks:
            thanksIllustration
        }
    }

    var hometteExpression: HometteExpression {
        switch page {
        case .record: .wave
        case .share: .point
        case .thanks: .holdHeart
        }
    }

    /// 終わった家事にチェックが付き、ポイントがたまっていく様子
    var recordIllustration: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text("今日の家事", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            VStack(spacing: .space8) {
                houseworkRow(title: .localized("洗濯"), point: 20, isCompleted: true)
                houseworkRow(title: .localized("食器洗い"), point: 15, isCompleted: true)
                houseworkRow(title: .localized("掃除機がけ"), point: 30, isCompleted: false)
            }
        }
    }

    /// 2人の分担を塗り分けたバー
    var shareIllustration: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text("今週の分担", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            MemberShareSummary(items: [
                memberShareItem(id: "self", name: .localized("たろう"), point: 55),
                memberShareItem(id: "partner", name: .localized("はなこ"), point: 45),
            ])
        }
    }

    /// パートナーの完了の通知と、返したありがとう
    var thanksIllustration: some View {
        VStack(alignment: .leading, spacing: .space16) {
            HStack(spacing: .space8) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.textAccent)
                Text("はなこさんが「お風呂掃除」を終えました", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.space8)
            .background {
                RoundedRectangle(radius: .radius12)
                    .fill(.backgroundScreen)
            }
            HStack(spacing: .space8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.textThanks)
                Text("ありがとう、助かったよ", bundle: #bundle)
                    .font(with: .boldCaption)
                    .foregroundStyle(.textThanks)
            }
            .padding(.vertical, .space8)
            .padding(.horizontal, .space16)
            .background {
                Capsule()
                    .fill(.fillThanksSubtle)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func memberShareItem(id: String, name: LocalizedStringResource, point: Int) -> MemberShareSummary.Item {
        .init(
            id: id,
            name: name.resolved(),
            value: point,
            detail: .localized("\(point)pt", comment: "見本のメンバーがもらったポイント")
        )
    }

    func houseworkRow(title: LocalizedStringResource, point: Int, isCompleted: Bool) -> some View {
        HStack(spacing: .space8) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? Color.fillAccent : Color.iconDecorative)
            Text(title)
                .font(with: .body)
                .foregroundStyle(isCompleted ? Color.textSecondary : Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: "+\(point)pt")
                .font(with: .boldCaption)
                .foregroundStyle(.textReward)
                .padding(.vertical, .space4)
                .padding(.horizontal, .space8)
                .background {
                    Capsule()
                        .fill(.fillRewardSubtle)
                }
                .opacity(isCompleted ? 1 : 0.4)
        }
    }

}

#Preview("WelcomeIllustration_記録", traits: .sizeThatFitsLayout) {
    WelcomeIllustration(page: .record)
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("WelcomeIllustration_分担", traits: .sizeThatFitsLayout) {
    WelcomeIllustration(page: .share)
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("WelcomeIllustration_ありがとう", traits: .sizeThatFitsLayout) {
    WelcomeIllustration(page: .thanks)
        .padding(.space16)
        .background(.backgroundScreen)
}
