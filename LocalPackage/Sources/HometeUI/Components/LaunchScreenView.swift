//
//  LaunchScreenView.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 起動状態の判定が終わるまで表示する、アプリ名とほめっとだけの画面
public struct LaunchScreenView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: .space16) {
            Text("Homete")
                .font(with: .headLineL)
            HometteView(.normal, size: .large)
            Spacer()
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space24)
        .trackScreenView(.launch)
    }

}

#Preview {
    LaunchScreenView()
}
