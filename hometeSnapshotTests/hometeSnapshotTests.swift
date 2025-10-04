//
//  hometeSnapshotTests.swift
//  hometeSnapshotTests
//
//  Created by 佐藤汰一 on 2025/10/04.
//

import SnapshotTesting
import SwiftUI
import Testing

@testable import homete

@MainActor
struct HometeViewsSnapshotTests {
    
    @Test func loginView() {
        let loginView = UIHostingController(rootView: PreviewLoginView())
        assertSnapshots(
            of: loginView,
            as: [
                .image(on: .iPhoneSe),
                .image(on: .iPhone13),
                .image(on: .iPhone13ProMax)
            ],
            record: true
        )
    }
}
