//
//  LoadingState.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/11.
//

import SwiftUI

@MainActor
@propertyWrapper
struct LoadingState: DynamicProperty {
    @State var store = LoadingStateStore()
    
    var wrappedValue: LoadingStateStore {
        return store
    }
    
    var projectedValue: Binding<LoadingStateStore> {
        return $store
    }
}

@MainActor
@Observable
final class LoadingStateStore {
    var isLoading: Bool
    
    init(isLoading: Bool = false) {
        
        self.isLoading = isLoading
    }
    
    func task(_ operation: @MainActor @escaping () async -> Void) {
        
        isLoading = true
        Task {
            
            await operation()
            isLoading = false
        }
    }
}
