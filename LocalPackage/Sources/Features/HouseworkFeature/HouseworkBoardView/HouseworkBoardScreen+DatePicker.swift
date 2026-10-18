//
//  HouseworkBoardScreen+DatePicker.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 年月ラベルのタップで開く、日付を選ぶカレンダー
extension HouseworkBoardScreen {

    func datePicker() -> some View {
        NavigationStack {
            HouseworkDatePickerView(
                selectedDate: dateList.selectedDate,
                selectableRange: dateList.selectableRange(calendar: calendar),
                hasStorageLimit: dateList.hasStorageLimit,
                onSelect: { selectedDateInDatePicker($0) },
                onTapClose: { isPresentingDatePicker = false },
                onTapStorageLimit: { tappedStorageLimitInDatePicker() }
            )
        }
        .presentationDragIndicator(.visible)
        .trackScreenView(.houseworkDatePicker)
    }

    func selectedDateInDatePicker(_ date: Date) {
        withAnimation {
            dateList.selectDate(date, calendar: calendar)
        }
        isPresentingDatePicker = false
    }

    func tappedStorageLimitInDatePicker() {
        hasPendingDatePickerPaywall = true
        isPresentingDatePicker = false
    }

}
