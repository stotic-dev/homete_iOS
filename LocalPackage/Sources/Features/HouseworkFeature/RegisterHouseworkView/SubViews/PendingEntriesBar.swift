//
//  PendingEntriesBar.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 家事の登録シートの下部に常に出す、登録予定リストの要約
/// - Note: 登録そのものはナビゲーションバーのボタンで行う。ここはタップして中身を見直すための導線
struct PendingEntriesBar: View {

    let entries: [PendingEntry]
    let onTapSummary: () -> Void

    var body: some View {
        summary()
            .padding(.space16)
            .background(.surface)
    }

}

private extension PendingEntriesBar {

    func summary() -> some View {
        Button {
            onTapSummary()
        } label: {
            HStack(spacing: .space8) {
                Text("登録予定 \(entries.count)件")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                Text(titleSummary)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
                    .lineLimit(1)
                Spacer()
                if !entries.isEmpty {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundStyle(.onSurfaceVariant)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entries.isEmpty)
    }

    var titleSummary: String {
        entries.map(\.title).joined(separator: "・")
    }

}

#if DEBUG
#Preview("PendingEntriesBar_0件", traits: .sizeThatFitsLayout) {
    PendingEntriesBar(
        entries: [],
        onTapSummary: {}
    )
}

#Preview("PendingEntriesBar_3件", traits: .sizeThatFitsLayout) {
    PendingEntriesBar(
        entries: [
            .init(
                source: .frequent(itemId: "1"),
                title: "布団干し",
                point: 20,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: nil
            ),
            .init(
                source: .frequent(itemId: "2"),
                title: "換気扇",
                point: 30,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: nil
            ),
            .init(
                source: .editing,
                title: "ゴミ出し",
                point: 10,
                recurrence: nil,
                savesAsFrequent: true,
                categoryId: nil
            ),
        ],
        onTapSummary: {}
    )
}
#endif
