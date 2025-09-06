//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardView: View {
    
    @State var selectedSegment: HouseworkBoardSegmentedControl.Segment = .incomplete
    
    var body: some View {
        VStack(spacing: DesignSystem.Space.space16) {
            HouseworkBoardSegmentedControl(selectedSegment: $selectedSegment)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

#Preview {
    HouseworkBoardView()
        .apply(theme: .init())
}
