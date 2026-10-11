//
//  View+Extension.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import HometeDomain
import SwiftUI

public extension View {

    func commonError(
        content: Binding<DomainErrorAlertContent>,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        alert(
            .localized("操作が完了しませんでした"),
            isPresented: content.wrappedValue.hasError ? content.isPresenting : .constant(false),
            actions: {
                Button("OK") {
                    onDismiss()
                }
            },
            message: {
                if let errorMessage = content.wrappedValue.errorMessage {
                    Text(errorMessage)
                }
            }
        )
    }

}
