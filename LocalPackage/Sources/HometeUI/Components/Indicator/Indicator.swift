//
//  Indicator.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

#if canImport(UIKit)
import SwiftUI

public struct Indicator: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .padding(.space16)
            .tint(.onSurface)
            .background(.primary3)
            .cornerRadius(.radius8)
    }
}
#endif
