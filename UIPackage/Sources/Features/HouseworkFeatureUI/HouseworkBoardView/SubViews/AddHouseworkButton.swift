//
//  AddHouseworkButton.swift
//  homete
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事の登録画面を開くボタン
public struct AddHouseworkButton: View {

    let action: () -> Void

    public init(
        action: @escaping () -> Void
    ) {
        self.action = action
    }

    public var body: some View {
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
