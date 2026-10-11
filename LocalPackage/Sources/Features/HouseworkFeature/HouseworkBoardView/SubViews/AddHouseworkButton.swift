//
//  AddHouseworkButton.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事の登録画面を開くボタン
struct AddHouseworkButton: View {

    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
        }
        .floatingButtonStyle()
        .accessibilityLabel(.localized("家事を追加する"))
    }

}

#if DEBUG
#Preview("AddHouseworkButton", traits: .sizeThatFitsLayout) {
    AddHouseworkButton {}
}
#endif
