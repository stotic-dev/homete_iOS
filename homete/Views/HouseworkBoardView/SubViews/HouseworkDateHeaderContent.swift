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
                // TODO: 前日の家事を表示する
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primaryFg)
            }
            Spacer()
            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Button {
                // TODO: 次の日の家事を表示する
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primaryFg)
            }
        }
    }
}
