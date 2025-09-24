//
//  EnvironmentBindableStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/19.
//

import SwiftUI

@MainActor
@propertyWrapper
struct EnvironmentBindableStore<Store: Storable>: DynamicProperty {
    
    @Environment(Store.self) private var store

    var wrappedValue: Store { store }
    
    var projectedValue: Bindable<Store> {
        
        return Bindable(wrappedValue: wrappedValue)
    }
}
