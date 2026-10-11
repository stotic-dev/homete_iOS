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
            HStack(alignment: .firstTextBaseline, spacing: .space4) {
                // 行に収まらない長さの家事名は、省略せずチップの中で折り返す
                Text(item.title)
                    .font(with: .body)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(item.point)pt")
                    .font(with: .caption)
                    .fixedSize()
                // 選択でチップの幅が変わると後ろのチップが別の行へ動くため、未選択でも幅を確保しておく
                Image(systemName: "checkmark")
                    .font(.caption)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(!isSelected)
            }
            .foregroundStyle(isSelected ? .textOnAccent : .textPrimary)
            .padding(.horizontal, .space8)
            .padding(.vertical, .space4)
            .frame(minWidth: 44, minHeight: 44)
            .background {
                RoundedRectangle(radius: .radius12)
                    .fill(isSelected ? Color.fillAccent : Color.fillAccentSubtle)
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

#Preview("FrequentHouseworkChip_長い家事名", traits: .sizeThatFitsLayout) {
    // 並べる行の幅を超える家事名は、チップの中で折り返す
    FrequentHouseworkChip(
        item: .makeForPreview(id: "1", title: "冷蔵庫の中の賞味期限切れの食品を確認して捨てる", point: 15),
        isSelected: true,
        isUsable: true,
        onTap: {}
    )
    .frame(width: 240, alignment: .leading)
    .padding()
}
#endif
