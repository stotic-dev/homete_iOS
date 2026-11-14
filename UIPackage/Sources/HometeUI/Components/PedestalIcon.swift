//
//  PedestalIcon.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// SF Symbolsを丸い台座に載せて表示する
///
/// 設定のメニューやメンバーの一覧など、行の先頭に置くアイコンに使う。
public struct PedestalIcon: View {

    let systemName: String

    public init(systemName: String) {
        self.systemName = systemName
    }

    public var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .padding(.space8)
            .foregroundStyle(.textPrimary)
            .background(.fillAccentSubtle, in: Circle())
    }

}

#Preview("PedestalIcon", traits: .sizeThatFitsLayout) {
    HStack(spacing: .space16) {
        PedestalIcon(systemName: "person.circle.fill")
        PedestalIcon(systemName: "bell.badge.fill")
        PedestalIcon(systemName: "star.square.on.square")
    }
}
