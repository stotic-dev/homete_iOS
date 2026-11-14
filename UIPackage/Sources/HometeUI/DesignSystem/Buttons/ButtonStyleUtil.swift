//
//  ButtonStyleUtil.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

@MainActor
extension ButtonStyleConfiguration {

    /// ボタンの高さの下限。指で押しやすい大きさを保つ
    static let minHeight: CGFloat = 48

    /// - Parameters:
    ///   - foregroundColor: 文字の色
    ///   - dimsOnPress: 押している間、文字を薄くして押したことを示すか。押すと沈むボタンは沈み込みで示すため薄くしない
    func commonStyle(_ foregroundColor: Color = .textPrimary, dimsOnPress: Bool = true) -> some View {
        label
            .font(with: .headLineS)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .frame(minHeight: Self.minHeight)
            .foregroundStyle(
                foregroundColor.opacity(dimsOnPress && isPressed ? 0.3 : 1)
            )
    }

}
