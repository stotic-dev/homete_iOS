//
//  HouseworkDateHeaderContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkDateHeaderContent: View {
    
    @Environment(\.calendar) var calendar
    
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Button {
                updateSelectedDate(value: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primaryFg)
            }
            Spacer()
            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Button {
                updateSelectedDate(value: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primaryFg)
            }
        }
    }
}

private extension HouseworkDateHeaderContent {
    
    func updateSelectedDate(value: Int) {
        
        withAnimation {
            
            selectedDate = calendar.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        }
    }
}
