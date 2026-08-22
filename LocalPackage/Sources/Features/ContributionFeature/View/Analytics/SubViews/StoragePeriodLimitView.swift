//
//  StoragePeriodLimitView.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 無料プランの保存期間より過去を表示しようとしたときの空状態
struct StoragePeriodLimitView: View {

    let onUpgradeTapped: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("この期間は表示できません", systemImage: "lock.fill")
        } description: {
            Text("プレミアムプランに登録すると、全期間の家事データを振り返れます")
        } actions: {
            Button("プレミアムプランを見る", action: onUpgradeTapped)
                .subPrimaryButtonStyle()
        }
    }

}

#if DEBUG
#Preview("StoragePeriodLimitView") {
    StoragePeriodLimitView {}
        .setupEnvironmentForPreview()
}
#endif
