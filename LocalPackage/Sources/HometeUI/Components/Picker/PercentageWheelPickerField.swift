//
//  PercentageWheelPickerField.swift
//  LocalPackage
//

import SwiftUI

/// 割合（%）をドラムロール（wheelスタイルのPicker）のポップアップで選択させる入力コンポーネント。
public struct PercentageWheelPickerField: View {

    @Binding var percentage: Int
    let range: ClosedRange<Int>
    let accessibilityName: String

    @State private var isShowingPicker = false

    /// - Parameter accessibilityName: VoiceOverで読み上げる、何の割合かを表す名前
    public init(percentage: Binding<Int>, range: ClosedRange<Int>, accessibilityName: String) {
        _percentage = percentage
        self.range = range
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(accessibilityName)の割合"))
        .accessibilityValue(Text("\(percentage)%"))
        .popover(isPresented: $isShowingPicker) {
            percentagePicker()
        }
    }

}

private extension PercentageWheelPickerField {

    func label() -> some View {
        HStack(spacing: .space4) {
            Text("\(percentage)%")
                .monospacedDigit()
            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.small)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .contentShape(Rectangle())
    }

    func percentagePicker() -> some View {
        Picker("割合", selection: $percentage) {
            ForEach(range, id: \.self) { value in
                Text("\(value)%").tag(value)
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

}

#if DEBUG
#Preview("PercentageWheelPickerField", traits: .sizeThatFitsLayout) {
    PercentageWheelPickerField(percentage: .constant(34), range: 1 ... 99, accessibilityName: "自分")
        .font(with: .body)
        .padding()
}
#endif
