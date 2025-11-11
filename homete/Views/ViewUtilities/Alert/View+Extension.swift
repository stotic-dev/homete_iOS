//
//  View+Extension.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import SwiftUI

extension View {
    
    func commonError(
        content: Binding<DomainErrorAlertContent>,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        self
            .alert("操作が完了しませんでした",
                   isPresented: content.wrappedValue.hasError ? content.isPresenting : .constant(false),
                   actions: {
                Button("OK") {
                    onDismiss()
                }
            }, message: {
                Text(content.wrappedValue.errorMessage ?? "")
            })
    }
}
