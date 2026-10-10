//
//  HouseworkDetailItemListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct HouseworkDetailItemListContent: View {

    @Environment(\.calendar) var calendar

    let cohabitantMemberList: CohabitantMemberList
    let item: HouseworkBoardItem
    /// 家事に届いたありがとう。届いていなければ空
    var thanksMessages: [HouseworkThanksMessage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: .space24) {
            SectionCard(.localized("家事の情報")) {
                HouseworkDetailItemRow(title: .localized("予定日")) {
                    valueText(item.formattedIndexedDate(calendar: calendar))
                }
                Divider()
                HouseworkDetailItemRow(title: .localized("ステータス")) {
                    Text(item.state.segmentTitle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
                }
                Divider()
                HouseworkDetailItemRow(title: .localized("ポイント")) {
                    PointLabel(point: item.earnedPoint)
                }
                if let effortLabel {
                    Divider()
                    HouseworkDetailItemRow(title: .localized("がんばり")) {
                        valueText(effortLabel)
                    }
                }
            }
            if !executors.isEmpty {
                SectionCard(.localized("担当者")) {
                    ForEach(Array(executors.enumerated()), id: \.element.userId) { index, executor in
                        if index > 0 {
                            Divider()
                        }
                        executorRow(executor)
                    }
                }
            }
            if !thanksMessages.isEmpty {
                SectionCard(.localized("ありがとう")) {
                    ForEach(thanksMessages.indices, id: \.self) { index in
                        if index > 0 {
                            Divider()
                        }
                        thanksMessageRow(thanksMessages[index])
                    }
                }
            }
        }
    }

}

private extension HouseworkDetailItemListContent {

    /// グループのメンバーの担当者（グループを抜けたメンバーは名前が分からないため出さない）
    var executors: [HouseworkExecutor] {
        item.executors.filter { cohabitantMemberList.userName($0.userId) != nil }
    }

    /// 完了した家事の頑張り度。上乗せしたときはポイントの内訳を添える（例: `がんばった（10pt → 12pt）`）
    var effortLabel: LocalizedStringResource? {
        guard item.state == .completed else { return nil }

        guard let pointBreakdown = item.effort.pointBreakdown(basePoint: item.originalItem.point) else {
            return item.effort.title
        }
        return .localized(
            "\(item.effort.title)（\(pointBreakdown)）",
            comment: "1つめはがんばり、2つめはポイントの内訳（例: がんばった（10pt → 12pt））"
        )
    }

    /// 複数人で担当した家事は、名前の横に割合とポイントを添える（例: `60%（6pt）`）
    func executorShareLabel(_ executor: HouseworkExecutor) -> String? {
        guard item.executors.count > 1 else { return nil }

        return "\(executor.percentage)%（\(executor.point)pt）"
    }

    func valueText(_ value: String) -> some View {
        valueText(Text(value))
    }

    func valueText(_ value: LocalizedStringResource) -> some View {
        valueText(Text(value))
    }

    func valueText(_ text: Text) -> some View {
        text
            .font(with: .body)
            .foregroundStyle(.textSecondary)
    }

    func executorRow(_ executor: HouseworkExecutor) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .space16) {
            Text(cohabitantMemberList.userName(executor.userId) ?? "")
                .font(with: .body)
                .foregroundStyle(.textPrimary)
            Spacer(minLength: .zero)
            if let shareLabel = executorShareLabel(executor) {
                valueText(shareLabel)
            }
        }
        .accessibilityElement(children: .combine)
    }

    func thanksMessageRow(_ thanksMessage: HouseworkThanksMessage) -> some View {
        VStack(alignment: .leading, spacing: .space4) {
            Label {
                Text("\(thanksMessage.senderName)さんから", bundle: #bundle)
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.fillThanks)
            }
            .font(with: .boldCaption)
            .foregroundStyle(.textPrimary)
            // メッセージを書かずに伝えたありがとうは、ハートをタップしたときの気持ちを代わりに添える
            (thanksMessage.comment.map { Text(verbatim: $0) } ?? Text("ありがとう！", bundle: #bundle))
                .font(with: .body)
                .foregroundStyle(.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

}

#if DEBUG
#Preview("HouseworkDetailItemListContent_未完了時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(value: [], ownId: ""),
        item: .makeForPreview(
            title: "洗濯",
            point: 10
        )
    )
    .padding()
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_完了時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "test", userName: "hogehoge")],
            ownId: "test"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "test",
            executedAt: .distantPast
        )
    )
    .padding()
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_複数人で担当", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                .init(userId: "own", percentage: 60, point: 6),
                .init(userId: "partner", percentage: 40, point: 4),
            ],
            executedAt: .distantPast
        )
    )
    .padding()
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_ありがとうあり", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "own",
            executedAt: .distantPast
        ),
        thanksMessages: [
            .init(senderName: "はなこ", comment: "いつも洗濯してくれてありがとう！助かっています。"),
            .init(senderName: "じろう", comment: nil),
        ]
    )
    .padding()
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_がんばった", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "test", userName: "hogehoge")],
            ownId: "test"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "test",
            effort: .hard,
            executedAt: .distantPast
        )
    )
    .padding()
    .setupEnvironmentForPreview()
}
#endif
