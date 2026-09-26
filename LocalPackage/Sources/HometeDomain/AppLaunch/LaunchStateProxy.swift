//
//  LaunchStateProxy.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import SwiftUI

/// 画面側から`LaunchState`を差し替えるための入口
/// - Note: `LaunchState`の実体は`LaunchStateStore`が持つため、差し替え手段だけを渡す
public struct LaunchStateProxy {

    private let update: @MainActor (LaunchState) -> Void

    public init(_ update: @escaping @MainActor (LaunchState) -> Void) {
        self.update = update
    }

    /// `Binding`で状態を持つ画面（デバッグ画面など）用
    @MainActor
    public init(launchState: Binding<LaunchState>) {
        self.init { launchState.wrappedValue = $0 }
    }

    @MainActor
    public func callAsFunction(_ next: LaunchState) {
        update(next)
    }

}

public extension EnvironmentValues {

    @Entry var launchStateProxy = LaunchStateProxy { _ in }

}
