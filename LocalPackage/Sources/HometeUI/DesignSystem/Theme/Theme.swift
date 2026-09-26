//
//  Theme.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

@MainActor
public struct Theme {

    public let segmentedControl: SegmentedControl

    public init(segmentedControl: SegmentedControl = .init()) {
        self.segmentedControl = segmentedControl
    }

}

public extension View {

    func apply(theme: Theme) -> some View {
        onAppear {
            theme.applySegmentedControl()
        }
    }

}

// MARK: - セグメントボタンの定義

public extension Theme {

    struct SegmentedControl {

        public let backgroundColor: Color
        public let selectedForegroundColor: Color
        public let foregroundColor: Color

        public init() {
            backgroundColor = .primary3
            selectedForegroundColor = .onSurface
            foregroundColor = .onSurfaceVariant
        }

        public init(
            backgroundColor: Color,
            selectedForegroundColor: Color,
            foregroundColor: Color
        ) {
            self.backgroundColor = backgroundColor
            self.selectedForegroundColor = selectedForegroundColor
            self.foregroundColor = foregroundColor
        }

    }

    func applySegmentedControl() {
        #if canImport(UIKit)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(segmentedControl.foregroundColor)],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(segmentedControl.selectedForegroundColor)],
            for: .selected
        )
        UISegmentedControl.appearance().backgroundColor = UIColor(segmentedControl.backgroundColor)
        #endif
    }

}
