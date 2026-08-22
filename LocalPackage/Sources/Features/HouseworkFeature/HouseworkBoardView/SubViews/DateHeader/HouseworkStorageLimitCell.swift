//
//  HouseworkStorageLimitCell.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 家事ボードの日付リスト先頭に置く、保存期間の上限を示すセル
///
/// 無料プランでこれ以上過去に遡れないことを伝え、タップでPaywallへ誘導する。
struct HouseworkStorageLimitCell: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: .space4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                Text("これ以前")
                    .font(with: .caption)
            }
            .foregroundStyle(.onPrimary3)
            .frame(width: 60, height: 60)
            .background {
                Circle()
                    .fill(.primary3)
            }
            .padding(2)
        }
        .accessibilityLabel("これ以前の家事を見るにはプレミアムプランへの登録が必要です")
    }

}

#if DEBUG
#Preview("HouseworkStorageLimitCell", traits: .sizeThatFitsLayout) {
    HouseworkStorageLimitCell {}
        .setupEnvironmentForPreview()
}
#endif
