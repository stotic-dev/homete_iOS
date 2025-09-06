//
//  Theme.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

@MainActor
struct Theme {
    
    let segmentedControl: SegmentedControl
    
    init(segmentedControl: SegmentedControl = .init()) {
        
        self.segmentedControl = segmentedControl
    }
}

extension View {
    
    func apply(theme: Theme) -> some View {
        self.onAppear {
            theme.applySegmentedControl()
        }
    }
}

// MARK: - セグメントボタンの定義

extension Theme {
    
    struct SegmentedControl {
        
        let backgroundColor: ColorResource
        let selectedForegroundColor: ColorResource
        let foregroundColor: ColorResource
        
        init(
            backgroundColor: ColorResource = .primary3,
            selectedForegroundColor: ColorResource = .primaryFg,
            foregroundColor: ColorResource = .primary2
        ) {
            
            self.backgroundColor = backgroundColor
            self.selectedForegroundColor = selectedForegroundColor
            self.foregroundColor = foregroundColor
        }
    }
    
    func applySegmentedControl() {
        
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(.primary2)],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(.primaryFg)],
            for: .selected
        )
        UISegmentedControl.appearance().backgroundColor = .primary3
    }
}
