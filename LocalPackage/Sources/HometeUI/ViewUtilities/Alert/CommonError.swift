//
//  CommonError.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/11.
//

import SwiftUI

@propertyWrapper
public struct CommonError: DynamicProperty {

    @State var _content: DomainErrorAlertContent = .initial

    public init() {}

    public var wrappedValue: DomainErrorAlertContent {
        get {
            return _content
        }
        nonmutating set {
            _content = newValue
        }
    }

    public var projectedValue: Binding<DomainErrorAlertContent> {
        return $_content
    }
}
