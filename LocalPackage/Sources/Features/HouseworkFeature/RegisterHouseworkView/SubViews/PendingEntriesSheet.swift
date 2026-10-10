//
//  PendingEntriesSheet.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 登録予定リストの一覧（要約をタップして開く）
/// - Note: ここではポイントを変えられない。間違えた場合は取り消して入力し直す
struct PendingEntriesSheet: View {

    let entries: [PendingEntry]
    let onTapRemove: (PendingEntry) -> Void
    let onTapClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    entryRow(entry)
                }
            }
            .navigationTitle(.localized("登録予定"))
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                NavigationBarButton(label: .close) {
                    onTapClose()
                }
            }
        }
        .presentationDetents([.medium])
    }

}

private extension PendingEntriesSheet {

    func entryRow(_ entry: PendingEntry) -> some View {
        HStack(spacing: .space8) {
            VStack(alignment: .leading, spacing: .space4) {
                Text(entry.title)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
                if let recurrence = entry.recurrence {
                    Text("テンプレートに登録（\(recurrence.scheduleLabel)）", bundle: #bundle)
                        .font(with: .caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            PointLabel(point: entry.point)
            Button {
                onTapRemove(entry)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(.localized("\(entry.title)を取り消す"))
        }
    }

}

#if DEBUG
#Preview("PendingEntriesSheet_3件") {
    PendingEntriesSheet(
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
                source: .queued(entryId: "2"),
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
                recurrence: .weekly([.thursday]),
                savesAsFrequent: true,
                categoryId: nil
            ),
        ],
        onTapRemove: { _ in },
        onTapClose: {}
    )
}
#endif
