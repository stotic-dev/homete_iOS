//
//  PointWheelPickerField.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/29.
//

import SwiftUI

/// ポイント値をドラムロール（wheelスタイルのPicker）のポップアップで選択させる入力コンポーネント。
///
/// 未選択状態（`point`が`nil`）を扱いたい場合は`Binding<Int?>`を受け取るイニシャライザを使う。
/// 常に有効な値を持つ場合は`Binding<Int>`を渡せばよい。
public struct PointWheelPickerField: View {

    @Binding var point: Int?
    let range: ClosedRange<Int>
    let placeholder: LocalizedStringKey

    @State private var isShowingPicker = false

    public init(
        point: Binding<Int?>,
        range: ClosedRange<Int> = 1 ... 100,
        placeholder: LocalizedStringKey = "未選択"
    ) {
        _point = point
        self.range = range
        self.placeholder = placeholder
    }

    public init(point: Binding<Int>, range: ClosedRange<Int> = 1 ... 100) {
        let optionalPoint: Binding<Int?> = Binding(
            get: { point.wrappedValue },
            set: { newValue in
                if let newValue {
                    point.wrappedValue = newValue
                }
            }
        )
        self.init(point: optionalPoint, range: range)
    }

    public var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ポイント")
        .accessibilityValue(point.map { Text($0.formatted()) } ?? Text(placeholder))
        .popover(isPresented: $isShowingPicker) {
            pointPicker()
        }
    }

}

private extension PointWheelPickerField {

    func label() -> some View {
        HStack(spacing: .space4) {
            if let point {
                Text(point.formatted())
            } else {
                Text(placeholder)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.small)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .contentShape(Rectangle())
    }

    func pointPicker() -> some View {
        Picker("ポイント", selection: selectedPointBinding) {
            ForEach(range, id: \.self) { value in
                Text(value.formatted()).tag(value)
            }
        }
        #if os(iOS)
        .pickerStyle(.wheel)
        #endif
        .labelsHidden()
        .font(with: .body)
        .frame(width: 160, height: 180)
        .presentationCompactAdaptation(.popover)
    }

    var selectedPointBinding: Binding<Int> {
        Binding(
            get: { point ?? range.lowerBound },
            set: { point = $0 }
        )
    }

}

#if DEBUG
#Preview("PointWheelPickerField_選択済み", traits: .sizeThatFitsLayout) {
    PointWheelPickerField(point: .constant(10))
        .font(with: .headLineL)
        .padding()
}

#Preview("PointWheelPickerField_未選択", traits: .sizeThatFitsLayout) {
    PointWheelPickerField(point: .constant(nil))
        .font(with: .headLineL)
        .padding()
}
#endif
