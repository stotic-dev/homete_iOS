//
//  HouseworkBoardSegmentedControl.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardSegmentedControl: View {
    
    @Binding var selectedHouseworkState: HouseworkState
    
    var body: some View {
        Picker("", selection: $selectedHouseworkState) {
            ForEach(HouseworkState.allCases) { state in
                Text(state.segmentTitle).tag(state)
            }
        }
        .pickerStyle(.segmented)
    }
}

extension HouseworkState {
    
    var segmentTitle: LocalizedStringKey {
        
        switch self {
            
        case .incomplete: "未完了"
        case .pendingApproval: "承認待ち"
        case .completed: "完了"
        }
    }
}
