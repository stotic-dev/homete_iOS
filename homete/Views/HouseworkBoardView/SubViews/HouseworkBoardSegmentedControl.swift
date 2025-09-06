//
//  HouseworkBoardSegmentedControl.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardSegmentedControl: View {
    
    @Binding private var selectedSegment: Segment
    
    var body: some View {
        Picker("", selection: $selectedSegment) {
            ForEach(Segment.allCases) { segment in
                Text(segment.title).tag(segment)
                    .foregroundStyle(selectedSegment == segment ? .primaryFg : .primary1)
            }
        }
        .pickerStyle(.segmented)
    }
}

 extension HouseworkBoardSegmentedControl {
    
     enum Segment: CaseIterable, Identifiable {
        case incomplete
        case pendingApproval
        case completed
        
        var id: String { rawValue }
        var title: LocalizedStringKey {
            
            switch self {
            case .incomplete: "未完了"
            case .pendingApproval: "承認待ち"
            case completed: "完了"
            }
        }
    }
}
