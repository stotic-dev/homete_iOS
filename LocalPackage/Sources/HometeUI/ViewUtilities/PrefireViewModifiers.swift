//
//  PrefireViewModifiers.swift
//  LocalPackage
//
//  Created by 佐藤汰一 on 2026/04/04.
//

import SwiftUI

#if canImport(Prefire)
import Prefire

public extension View {
    func snapshotForPreview(delay: Double) -> some View {
        snapshot(delay: delay)
    }
}
#else
public extension View {
    func snapshotForPreview(delay: Double) -> some View {
        self
    }
}
#endif
