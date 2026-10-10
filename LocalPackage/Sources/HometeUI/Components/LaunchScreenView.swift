//
//  LaunchScreenView.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import SwiftUI

/// 起動状態の判定が終わるまで表示する、アプリ名とアイコンだけの画面
public struct LaunchScreenView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: .space16) {
            Text("Homete")
                .font(with: .headLineL)
            Image(.launchScreenIcon)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius12)
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
