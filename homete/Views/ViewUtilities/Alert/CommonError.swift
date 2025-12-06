//
//  CommonError.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/11.
//

import SwiftUI

@propertyWrapper
struct CommonError: DynamicProperty {
    
    @State var _content: DomainErrorAlertContent = .initial
    
    var wrappedValue: DomainErrorAlertContent {
        get {
            return _content
        }
        nonmutating set {
            _content = newValue
        }
    }
    
    var projectedValue: Binding<DomainErrorAlertContent> {
        return $_content
    }
}
