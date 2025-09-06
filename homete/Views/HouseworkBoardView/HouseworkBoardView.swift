//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardView: View {
    
    enum Segment: String, CaseIterable, Identifiable {
        case incomplete = "未完了"
        case pendingApproval = "承認まち"
        case completed = "完了"
        
        var id: String { rawValue }
        var title: String { rawValue }
    }
    
    @State private var selectedSegment: Segment = .incomplete
    
    var body: some View {
        VStack(spacing: DesignSystem.Space.space16) {
            Picker("", selection: $selectedSegment) {
                ForEach(Segment.allCases) { segment in
                    Text(segment.title).tag(segment)
                        .foregroundStyle(selectedSegment == segment ? .primaryFg : .primary1)
                }
            }
            .pickerStyle(.segmented)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

#Preview {
    HouseworkBoardView()
        .apply(theme: .init())
}
