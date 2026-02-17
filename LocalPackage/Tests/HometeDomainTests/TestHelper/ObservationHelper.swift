//
//  ObservationHelper.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/12.
//

import Observation

enum ObservationHelper {
    
    /// Observableなオブジェクトのプロパティが変更を検知する
    /// - Parameters:
    ///   - apply: 変更を検知したいプロパティを返す
    ///   - onChange: 変更検知時に発火するクロージャ
    @MainActor
    static func continuousObservationTracking<T: Sendable>(
        _ apply: @escaping @MainActor @Sendable () -> T,
        onChange: @escaping @Sendable () -> Void
    ) {

        _ = withObservationTracking({ apply() }) {

            onChange()
            Task { @MainActor in
                continuousObservationTracking(apply, onChange: onChange)
            }
        }
    }
}
