//
//  HouseworkDatePickerView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事ボードで表示する日付をカレンダーから選ぶハーフモーダル
///
/// 日付セルを横にたどらずに、離れた日付へ移るためのもの。選べる範囲は日付セルと同じにする。
/// `NavigationStack`の中に置く前提で、ナビゲーションバーのボタンもここで並べる。
struct HouseworkDatePickerView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.timeZone) var timeZone

    @State var pickedDate: Date

    let selectableRange: ClosedRange<Date>
    /// 保存期間の上限があるか。あるときは、これより前を見るためのPaywallへの導線を出す
    let hasStorageLimit: Bool
    let onSelect: (Date) -> Void
    let onTapClose: () -> Void
    let onTapStorageLimit: () -> Void

    init(
        selectedDate: Date,
        selectableRange: ClosedRange<Date>,
        hasStorageLimit: Bool,
        onSelect: @escaping (Date) -> Void,
        onTapClose: @escaping () -> Void,
        onTapStorageLimit: @escaping () -> Void
    ) {
        self.selectableRange = selectableRange
        self.hasStorageLimit = hasStorageLimit
        self.onSelect = onSelect
        self.onTapClose = onTapClose
        self.onTapStorageLimit = onTapStorageLimit
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        pickedDate = selectedDate
    }

    var body: some View {
        ContentFittingSheetScrollView {
            VStack(spacing: .space16) {
                DatePicker(selection: $pickedDate, in: selectableRange, displayedComponents: .date) {
                    Text("日付", bundle: #bundle)
                }
                .datePickerStyle(.graphical)
                .labelsHidden()
                if hasStorageLimit {
                    storageLimitButton()
                }
            }
            .padding(.horizontal, .space16)
            .padding(.bottom, .space16)
        }
        .navigationTitle(.localized("日付を選ぶ"))
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close, action: onTapClose)
        }
        // 年月のホイールで月を切り替えても選択中の日付が動くため、選んだ時点では閉じず確定ボタンで反映する
        .trailingToolbarItem {
            NavigationBarPrimaryActionButton(systemImage: "checkmark") {
                onSelect(pickedDate)
            }
            .foregroundStyle(.textOnAccent)
        }
    }

}

// MARK: - UI定義

private extension HouseworkDatePickerView {

    var oldestSelectableDateText: String {
        let format = Date.FormatStyle(
            locale: locale,
            calendar: calendar,
            timeZone: timeZone
        )
        .month()
        .day()
        return selectableRange.lowerBound.formatted(format)
    }

    func storageLimitButton() -> some View {
        Button(action: onTapStorageLimit) {
            HStack(spacing: .space8) {
                Image(systemName: "lock.fill")
                    .accessibilityHidden(true)
                Text("\(oldestSelectableDateText)より前の家事は、プレミアムプランで見られます", bundle: #bundle)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: .zero)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
            .padding(.horizontal, .space8)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

}

#if DEBUG
#Preview("HouseworkDatePickerView_無料プラン") {
    NavigationStack {
        HouseworkDatePickerView(
            selectedDate: .previewDate(year: 2026, month: 1, day: 1),
            selectableRange: HouseworkDateList(
                anchorDate: .previewDate(year: 2026, month: 1, day: 1),
                calendar: .japanese,
                storagePolicy: .free
            )
            .selectableRange(calendar: .japanese),
            hasStorageLimit: true,
            onSelect: { _ in },
            onTapClose: {},
            onTapStorageLimit: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDatePickerView_プレミアムプラン") {
    NavigationStack {
        HouseworkDatePickerView(
            selectedDate: .previewDate(year: 2026, month: 1, day: 1),
            selectableRange: HouseworkDateList(
                anchorDate: .previewDate(year: 2026, month: 1, day: 1),
                calendar: .japanese,
                storagePolicy: .premium
            )
            .selectableRange(calendar: .japanese),
            hasStorageLimit: false,
            onSelect: { _ in },
            onTapClose: {},
            onTapStorageLimit: {}
        )
    }
    .setupEnvironmentForPreview()
}
#endif
