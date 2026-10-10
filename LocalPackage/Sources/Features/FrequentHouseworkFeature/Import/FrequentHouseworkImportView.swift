//
//  FrequentHouseworkImportView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// テンプレートの家事をいつもの家事に取り込むシート
struct FrequentHouseworkImportView: View {

    /// テンプレートの全曜日から集めた、名前で重複を除いた候補
    let candidates: [FrequentHouseworkImportCandidate]
    /// チェックが入っている候補の名前（登録済みのものを含む）
    let checkedTitles: Set<String>
    /// 取り込むボタンに出す件数
    let importCount: Int
    let onTapClose: () -> Void
    let onTapCandidate: (FrequentHouseworkImportCandidate) -> Void
    let onTapImport: () -> Void

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(.localized("テンプレートから取り込む"))
                .inlineNavigationBarTitleDisplayMode()
                .leadingToolbarItem {
                    NavigationBarButton(label: .close) {
                        onTapClose()
                    }
                }
                .trailingToolbarItem {
                    if !candidates.isEmpty {
                        importButton()
                    }
                }
        }
        .trackScreenView(.frequentHouseworkImport)
    }

}

// MARK: - UI定義

private extension FrequentHouseworkImportView {

    @ViewBuilder
    func content() -> some View {
        if candidates.isEmpty {
            emptyContent()
        } else {
            candidateList()
        }
    }

    func emptyContent() -> some View {
        VStack(spacing: .space16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.decorativeIcon)
            Text("テンプレートに家事がありません", bundle: #bundle)
                .font(with: .headLineS)
            Text("テンプレートに家事を登録すると、ここからまとめて取り込めます。", bundle: #bundle)
                .font(with: .body)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .space16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func candidateList() -> some View {
        List {
            Section {
                ForEach(candidates) { candidate in
                    candidateRow(candidate)
                }
            } header: {
                Text(importCount == 0 ? .localized("取り込む家事を選んでください") : .localized("\(importCount)件を取り込みます"))
            } footer: {
                Text("取り込んだ家事のカテゴリは未設定になります。あとから編集して変更できます。", bundle: #bundle)
            }
        }
    }

    func candidateRow(_ candidate: FrequentHouseworkImportCandidate) -> some View {
        Button {
            onTapCandidate(candidate)
        } label: {
            HStack(spacing: .space8) {
                Image(systemName: checkedTitles.contains(candidate.title) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checkedTitles.contains(candidate.title) ? Color.accent : Color.onSurfaceVariant)
                VStack(alignment: .leading, spacing: .space4) {
                    Text(candidate.title)
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                    if candidate.isAlreadyRegistered {
                        Text("登録済み", bundle: #bundle)
                            .font(with: .caption)
                            .foregroundStyle(.onSurfaceVariant)
                    }
                }
                Spacer()
                PointLabel(point: candidate.point)
            }
            .opacity(candidate.isAlreadyRegistered ? 0.5 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(candidate.isAlreadyRegistered)
    }

    func importButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            onTapImport()
        }
        .disabled(importCount == 0)
        .accessibilityLabel(.localized("\(importCount)件取り込む"))
    }

}

#if DEBUG
#Preview("FrequentHouseworkImportView_候補あり") {
    FrequentHouseworkImportView(
        candidates: [
            .init(title: "風呂掃除", point: 10, isAlreadyRegistered: false),
            .init(title: "洗濯", point: 20, isAlreadyRegistered: true),
            .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
        ],
        checkedTitles: ["洗濯", "風呂掃除"],
        importCount: 1,
        onTapClose: {},
        onTapCandidate: { _ in },
        onTapImport: {}
    )
}

#Preview("FrequentHouseworkImportView_候補なし") {
    FrequentHouseworkImportView(
        candidates: [],
        checkedTitles: [],
        importCount: 0,
        onTapClose: {},
        onTapCandidate: { _ in },
        onTapImport: {}
    )
}
#endif
