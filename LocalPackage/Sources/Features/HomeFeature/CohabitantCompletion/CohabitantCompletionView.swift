//
//  CohabitantCompletionView.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 同居人グループへの参加が完了したことを祝うView
///
/// P2Pでの登録完了と招待リンクからの参加完了で同じ演出を見せたいため、
/// 文言だけを差し替えられる共通のViewにしている。
struct CohabitantCompletionView: View {

    /// 祝いの見出し
    let title: String
    /// 見出しに続けて表示する説明
    let message: String
    /// 閉じるボタンをタップしたときの処理
    let onTapClose: () -> Void

    /// クラッカーが弾け終わったかどうか
    @State private var isCracked = false

    var body: some View {
        ZStack {
            VStack(spacing: .space16) {
                Text(title)
                    .font(with: .headLineL)
                Text(message)
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
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
            celebration()
                .ignoresSafeArea()
                // 紙片のレイヤーが閉じるボタンのタップを奪わないようにする
                .allowsHitTesting(false)
        }
    }

}

private extension CohabitantCompletionView {

    @ViewBuilder
    func celebration() -> some View {
        if isCracked {
            ConfettiRainView()
        } else {
            CrackerView {
                withAnimation {
                    isCracked = true
                }
            }
            .transition(.opacity)
        }
    }

}

#Preview("CohabitantCompletionView_登録完了") {
    CohabitantCompletionView(
        title: "登録が完了しました！",
        message: "これからは、あなたとパートナーの家事を分担し、協力していくことができます。"
    ) {}
}

#Preview("CohabitantCompletionView_参加完了") {
    CohabitantCompletionView(
        title: "グループに参加しました！",
        message: "これからは、グループのメンバーと家事を分担し、協力していくことができます。"
    ) {}
}
