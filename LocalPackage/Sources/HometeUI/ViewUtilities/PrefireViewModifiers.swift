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

        func snapshotForPreview(
            delay: Double = .zero,
            precision: Float = 1.0,
            perceptualPrecision: Float = 1.0
        ) -> some View {
            snapshot(delay: delay, precision: precision, perceptualPrecision: perceptualPrecision)
        }

    }
#else
    public extension View {

        func snapshotForPreview(
            delay _: Double = .zero,
            precision _: Float = 1.0,
            perceptualPrecision _: Float = 1.0
        ) -> some View {
            self
        }

    }
#endif
