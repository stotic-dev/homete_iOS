//
//  View+Extension.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import SwiftUI

extension View {
    
    func commonError(isPresented: Binding<Bool>,
                     error: Binding<DomainError?>,
                     onDismiss: @escaping () -> Void = {}) -> some View {
        self
            .onChange(of: error.wrappedValue) { _, newValue in
                if newValue != nil {
                    print("occurred domain error: \(String(describing: newValue))")
                    isPresented.wrappedValue = true
                }
            }
            .alert("操作が完了しませんでした",
                   isPresented: isPresented,
                   actions: {
                Button("OK") {
                    error.wrappedValue = nil
                    onDismiss()
                }
            }, message: {
                let error = error.wrappedValue ?? .other
                Text(error.message)
            })
    }
}
