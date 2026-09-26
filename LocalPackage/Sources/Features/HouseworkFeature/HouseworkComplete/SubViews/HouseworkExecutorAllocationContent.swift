//
//  HouseworkExecutorAllocationContent.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 担当者ごとの割合を調整する入力欄
struct HouseworkExecutorAllocationContent: View {

    struct Entry: Equatable, Identifiable {

        let userId: String
        let userName: String
        let percentage: Int

        var id: String {
            userId
        }

    }

    let entries: [Entry]
    let percentageRange: ClosedRange<Int>
    let onChangePercentage: (_ userId: String, _ percentage: Int) -> Void

    var body: some View {
        VStack(spacing: .space8) {
            ForEach(entries) { entry in
                HStack {
                    Text(entry.userName)
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                    Spacer()
                    PercentageWheelPickerField(
                        percentage: percentageBinding(entry),
                        range: percentageRange,
                        accessibilityName: entry.userName
                    )
                    .font(with: .body)
                }
            }
        }
    }

}

private extension HouseworkExecutorAllocationContent {

    func percentageBinding(_ entry: Entry) -> Binding<Int> {
        Binding(
            get: { entry.percentage },
            set: { onChangePercentage(entry.userId, $0) }
        )
    }

}

#if DEBUG
#Preview("HouseworkExecutorAllocationContent_2人", traits: .sizeThatFitsLayout) {
    HouseworkExecutorAllocationContent(
        entries: [
            .init(userId: "own", userName: "たいち", percentage: 60),
            .init(userId: "partner", userName: "はなこ", percentage: 40),
        ],
        percentageRange: 1 ... 99,
        onChangePercentage: { _, _ in }
    )
    .padding()
}

#Preview("HouseworkExecutorAllocationContent_3人", traits: .sizeThatFitsLayout) {
    HouseworkExecutorAllocationContent(
        entries: [
            .init(userId: "own", userName: "たいち", percentage: 24),
            .init(userId: "partner", userName: "はなこ", percentage: 33),
            .init(userId: "child", userName: "じろう", percentage: 33),
        ],
        percentageRange: 1 ... 99,
        onChangePercentage: { _, _ in }
    )
    .padding()
}
#endif
