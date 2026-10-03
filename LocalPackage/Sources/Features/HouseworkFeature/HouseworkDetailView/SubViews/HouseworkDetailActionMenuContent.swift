//
//  HouseworkDetailActionMenuContent.swift
//  LocalPackage
//

import SwiftUI

/// 家事詳細の「その他」をタップしたときに表示するメニューの内容
///
/// `Menu { }` の中身として使う。選んだアクションは呼び出し元に伝えるだけにして、
/// ハーフモーダルの提示とドメイン操作は画面側（`HouseworkDetailView`）に持たせる。
struct HouseworkDetailActionMenuContent: View {

    let actions: [HouseworkDetailAction]
    let onTap: (HouseworkDetailAction) -> Void

    var body: some View {
        ForEach(actions) { action in
            Button(action.label, systemImage: action.systemImage, role: action.role) {
                onTap(action)
            }
        }
    }

}

#if DEBUG
#Preview("HouseworkDetailActionMenuContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionMenuContent(actions: [.remove], onTap: { _ in })
}

#Preview("HouseworkDetailActionMenuContent_完了", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionMenuContent(
        actions: [.addHelper, .redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}

#Preview("HouseworkDetailActionMenuContent_完了_手伝った人を追加できない", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionMenuContent(
        actions: [.redo, .returnToIncomplete, .remove],
        onTap: { _ in }
    )
}
#endif
