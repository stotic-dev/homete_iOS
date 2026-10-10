//
//  FrequentHouseworkChip.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 選ぶ部品に並べる、いつもの家事1件のチップ
struct FrequentHouseworkChip: View {

    let item: FrequentHouseworkItem
    let isSelected: Bool
    /// 無料プランの上限内で使えるか
    let isUsable: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: .space4) {
                Text(item.title)
                    .font(with: .body)
                    .lineLimit(1)
                Spacer(minLength: .space4)
                Text("\(item.point)pt")
                    .font(with: .caption)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .foregroundStyle(isSelected ? .onPrimary1 : .onSurface)
            .padding(.horizontal, .space8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(isSelected ? Color.primary1 : Color.primary3)
            }
            .opacity(isUsable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isUsable)
        .accessibilityHint(isUsable ? Text(verbatim: "") : Text("プレミアムプランで使えます", bundle: #bundle))
    }

}

#if DEBUG
#Preview("FrequentHouseworkChip_未選択", traits: .sizeThatFitsLayout) {
    FrequentHouseworkChip(
        item: .makeForPreview(id: "1", title: "布団干し", point: 20),
        isSelected: false,
        isUsable: true,
        onTap: {}
    )
    .padding()
}

#Preview("FrequentHouseworkChip_選択中", traits: .sizeThatFitsLayout) {
    FrequentHouseworkChip(
        item: .makeForPreview(id: "1", title: "布団干し", point: 20),
        isSelected: true,
        isUsable: true,
        onTap: {}
    )
    .padding()
}

#Preview("FrequentHouseworkChip_上限超過", traits: .sizeThatFitsLayout) {
    FrequentHouseworkChip(
        item: .makeForPreview(id: "1", title: "布団干し", point: 20),
        isSelected: false,
        isUsable: false,
        onTap: {}
    )
    .padding()
}
#endif
