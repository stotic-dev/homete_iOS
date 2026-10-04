//
//  HouseworkCommentInputContent.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 家事の完了・ありがとうのハーフモーダルで使う、コメントの入力欄
struct HouseworkCommentInputContent: View {

    let title: String
    let placeholder: String
    @Binding var text: String
    /// 入力欄のフォーカス。開いた直後にキーボードを出すかどうかは呼び出し側で決める
    let focus: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            TextField(placeholder, text: $text, axis: .vertical)
                .focused(focus)
                .font(with: .body)
                .lineLimit(3 ... 6)
                .padding(.space16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background {
                    RoundedRectangle(radius: .radius8)
                        .fill(.subSurface)
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
        placeholder: "感謝を伝えましょう！",
        text: .constant("いつもありがとう！"),
        focus: $isShowingKeyboard
    )
    .padding()
}
#endif
