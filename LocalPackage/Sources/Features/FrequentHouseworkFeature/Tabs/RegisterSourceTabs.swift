//
//  RegisterSourceTabs.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 「いつもの家事 | 新しく入力」の2タブの枠
/// - Note: 家事の登録シートとテンプレートの追加モーダルで共用する。
///         上の切り替えとページのスワイプを同じ選択状態に結び付けるだけで、中身は呼び出し側が渡す
public struct RegisterSourceTabs<FrequentContent: View, ManualContent: View>: View {

    @Binding var selectedTab: RegisterSourceTab

    let frequentContent: FrequentContent
    let manualContent: ManualContent

    public init(
        selectedTab: Binding<RegisterSourceTab>,
        @ViewBuilder frequentContent: () -> FrequentContent,
        @ViewBuilder manualContent: () -> ManualContent
    ) {
        _selectedTab = selectedTab
        self.frequentContent = frequentContent()
        self.manualContent = manualContent()
    }

    public var body: some View {
        VStack(spacing: .space8) {
            Picker("入力方法", selection: $selectedTab) {
                ForEach(RegisterSourceTab.allCases) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, .space16)
            pages()
        }
    }

}

private extension RegisterSourceTabs {

    /// - Note: `TabView`のページングはiOSにしかないため、他のプラットフォームでは選んでいる方だけを描画する
    @ViewBuilder
    func pages() -> some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            frequentContent
                .tag(RegisterSourceTab.frequent)
            manualContent
                .tag(RegisterSourceTab.manual)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        switch selectedTab {
        case .frequent:
            frequentContent

        case .manual:
            manualContent
        }
        #endif
    }

}

#if DEBUG
#Preview("RegisterSourceTabs_いつもの家事") {
    RegisterSourceTabs(selectedTab: .constant(.frequent)) {
        Text("いつもの家事の中身")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    } manualContent: {
        Text("新しく入力の中身")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("RegisterSourceTabs_新しく入力") {
    RegisterSourceTabs(selectedTab: .constant(.manual)) {
        Text("いつもの家事の中身")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    } manualContent: {
        Text("新しく入力の中身")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
