//
//  Theme.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

#if canImport(UIKit)
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
        self.onAppear {
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
            foregroundColor = .onPrimary3
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

        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Color.primary2)],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Color.onSurface)],
            for: .selected
        )
        UISegmentedControl.appearance().backgroundColor = UIColor(Color.primary3)
    }
}
#endif
