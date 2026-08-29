//
//  CohabitantJoinCompletedView.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 招待リンクからのグループ参加が完了したことを伝えるView
struct CohabitantJoinCompletedView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: .space16) {
            Text("グループに参加しました！")
                .font(with: .headLineL)
            Text("これからは、グループのメンバーと家事を分担し、協力していくことができます。")
                .font(with: .body)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("閉じる")
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
        }
    }

}

#Preview {
    CohabitantJoinCompletedView()
}
