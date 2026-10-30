//
//  HouseworkPostponeDatePickerView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事詳細から、家事をまわす日をカレンダーで選ぶハーフモーダル
///
/// 選べるのは今日から、家事ボードで選べる最も先の日まで（`HouseworkPostponeDateRange`）。
/// `NavigationStack`の中に置く前提で、ナビゲーションバーのボタンもここで並べる。
struct HouseworkPostponeDatePickerView: View {

    @Environment(\.calendar) var calendar

    @State var pickedDate: Date

    let dateRange: HouseworkPostponeDateRange
    let onSelect: (Date) -> Void
    let onTapClose: () -> Void

    init(
        dateRange: HouseworkPostponeDateRange,
        onSelect: @escaping (Date) -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.dateRange = dateRange
        self.onSelect = onSelect
        self.onTapClose = onTapClose
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        pickedDate = dateRange.initialDate
    }

    var body: some View {
        ContentFittingSheetScrollView {
            DatePicker(selection: $pickedDate, in: dateRange.selectableRange, displayedComponents: .date) {
                Text("日付", bundle: #bundle)
            }
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, .space16)
            .padding(.bottom, .space16)
        }
        .navigationTitle(.localized("まわす日を選ぶ"))
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
            // 家事の今の日付を選んだままでは、まわしても何も変わらない
            .disabled(!dateRange.canPostpone(to: pickedDate, calendar: calendar))
        }
    }

}

#if DEBUG
#Preview("HouseworkPostponeDatePickerView_今日の家事") {
    NavigationStack {
        HouseworkPostponeDatePickerView(
            dateRange: .init(
                itemDate: .previewDate(year: 2026, month: 1, day: 1),
                now: .previewDate(year: 2026, month: 1, day: 1),
                calendar: .japanese
            ),
            onSelect: { _ in },
            onTapClose: {}
        )
    }
    .setupEnvironmentForPreview()
}
#endif
