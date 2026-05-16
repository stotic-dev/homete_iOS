//
//  ClearableTextField.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import HometeResources
import SwiftUI

/// クリアボタン付きテキストフィールド。
/// 入力中はクリアボタンが表示され、タップで入力をクリアできる。
public struct ClearableTextField: View {

    @Binding public var text: String
    public let placeholder: String
    public let focus: FocusState<Bool>.Binding

    public init(
        text: Binding<String>,
        placeholder: String,
        focus: FocusState<Bool>.Binding
    ) {
        _text = text
        self.placeholder = placeholder
        self.focus = focus
    }

    public var body: some View {
        ZStack {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(.primary2.opacity(0.7))
            )
            .focused(focus)
            .foregroundStyle(.primary2)
            .padding()
            .font(with: .body)
            .background {
                RoundedRectangle(radius: .radius8)
                    .foregroundStyle(.primary3)
            }
            Button {
                text = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.primary2)
                    .padding(.space8)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, .space8)
            .opacity(text.isEmpty ? 0 : 1)
        }
    }

}

#if DEBUG
#Preview("ClearableTextField_未入力", traits: .sizeThatFitsLayout) {
    @Previewable @FocusState var isFocused: Bool
    ClearableTextField(
        text: .constant(""),
        placeholder: "家事の名前を入力",
        focus: $isFocused
    )
    .padding(.space16)
}

#Preview("ClearableTextField_入力済み", traits: .sizeThatFitsLayout) {
    @Previewable @FocusState var isFocused: Bool
    ClearableTextField(
        text: .constant("洗濯"),
        placeholder: "家事の名前を入力",
        focus: $isFocused
    )
    .padding(.space16)
}
#endif
