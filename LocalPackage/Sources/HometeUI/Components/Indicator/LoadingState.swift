//
//  LoadingState.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/11.
//

#if canImport(UIKit)
import SwiftUI

@MainActor
@propertyWrapper
public struct LoadingState: DynamicProperty {
    @State public var store: LoadingStateStore

    public init() {
        self._store = State(initialValue: LoadingStateStore())
    }

    public init(store: LoadingStateStore) {
        self._store = State(initialValue: store)
    }

    public var wrappedValue: LoadingStateStore {
        return store
    }

    public var projectedValue: Binding<LoadingStateStore> {
        return $store
    }
}

@MainActor
@Observable
public final class LoadingStateStore {
    public var isLoading: Bool

    public init(isLoading: Bool = false) {

        self.isLoading = isLoading
    }

    public func task(_ operation: @MainActor @escaping () async -> Void) {

        isLoading = true
        Task {

            await operation()
            isLoading = false
        }
    }
}
#endif
