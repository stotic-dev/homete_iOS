//
//  HouseworkCommentInputContent.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 家事の完了・ありがとうのハーフモーダルで使う、コメントの入力欄
struct HouseworkCommentInputContent: View {

    let title: LocalizedStringResource
    let placeholder: LocalizedStringResource
    @Binding var text: String
    /// 入力欄のフォーカス。開いた直後にキーボードを出すかどうかは呼び出し側で決める
    let focus: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            TextField(placeholder, text: $text, axis: .vertical)
                .focused(focus)
                .font(with: .body)
                // 入力した行数で高さが変わると、それに合わせてシートの高さも動いてしまうため、3行で固定する
                // （3行を超えた分は入力欄の中でスクロールする）
                .lineLimit(3, reservesSpace: true)
                .padding(.space16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background {
                    RoundedRectangle(radius: .radius12)
                        .fill(.backgroundCard)
                }
        }
    }

}

#if DEBUG
#Preview("HouseworkCommentInputContent_未入力", traits: .sizeThatFitsLayout) {
    @Previewable @FocusState var isShowingKeyboard: Bool

    HouseworkCommentInputContent(
        title: "コメント（任意）",
        placeholder: "ひとこと添えられます",
        text: .constant(""),
        focus: $isShowingKeyboard
    )
    .padding()
}

#Preview("HouseworkCommentInputContent_入力済み", traits: .sizeThatFitsLayout) {
    @Previewable @FocusState var isShowingKeyboard: Bool

    HouseworkCommentInputContent(
        title: "メッセージ",
        placeholder: "ひとこと添えてみませんか（例：助かったよ）",
        text: .constant("いつもありがとう！"),
        focus: $isShowingKeyboard
    )
    .padding()
}
#endif
