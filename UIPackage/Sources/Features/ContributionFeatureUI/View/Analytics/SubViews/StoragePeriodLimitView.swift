//
//  StoragePeriodLimitView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 無料プランの保存期間より過去を表示しようとしたときの空状態
public struct StoragePeriodLimitView: View {

    let onUpgradeTapped: () -> Void

    public init(
        onUpgradeTapped: @escaping () -> Void
    ) {
        self.onUpgradeTapped = onUpgradeTapped
    }

    public var body: some View {
        ContentUnavailableView {
            Label(.localized("この期間は表示できません"), systemImage: "lock.fill")
        } description: {
            Text("プレミアムプランに登録すると、全期間の家事データを振り返れます", bundle: #bundle)
        } actions: {
            Button(.localized("プレミアムプランを見る"), action: onUpgradeTapped)
                .primaryButtonStyle()
        }
    }

}

#if DEBUG
#Preview("StoragePeriodLimitView") {
    StoragePeriodLimitView {}
        .setupEnvironmentForPreview()
}
#endif
