//
//  PendingEntriesButton.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事の登録シートの下部に浮かべる、登録予定リストを開くボタン
/// - Note: 登録そのものはナビゲーションバーのボタンで行う。ここはタップして中身を見直すための導線。
///         見直す中身がない0件のときに出さない判断は、登録予定リストを持つ呼び出し側に任せる
struct PendingEntriesButton: View {

    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: .space4) {
                Image(systemName: "checklist")
                Text("登録予定 \(count)件", bundle: #bundle)
            }
            .font(with: .headLineS)
        }
        .floatingButtonStyle()
        .accessibilityLabel(.localized("登録予定\(count)件を見る"))
    }

}

#if DEBUG
#Preview("PendingEntriesButton_3件", traits: .sizeThatFitsLayout) {
    PendingEntriesButton(count: 3, onTap: {})
}
#endif
