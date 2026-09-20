//
//  CohabitantJoinAlreadyMemberView.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 自分が参加済みのグループの招待リンクを開いたことを伝えるView
///
/// 参加は発生していないため、完了の演出ではなく案内として表示する。
struct CohabitantJoinAlreadyMemberView: View {

    let onTapClose: () -> Void

    var body: some View {
        VStack(spacing: .space16) {
            Text("すでにこのグループに参加しています")
                .font(with: .headLineL)
            Text("招待されたグループには参加済みなので、このまま家事の管理を続けられます。")
                .font(with: .body)
            Spacer()
            Button {
                onTapClose()
            } label: {
                Text("閉じる")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }

}

#Preview {
    CohabitantJoinAlreadyMemberView {}
}
