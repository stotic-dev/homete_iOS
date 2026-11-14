//
//  TrackScreenViewModifier.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// 画面の表示を`screen_view`イベントとして送信するModifier
/// - Note: SwiftUIのみで構成しているためFirebase Analyticsの自動収集（`UIViewController`単位）が機能しない。
///         各画面がこのModifierを付けることで、画面の表示を計測する
struct TrackScreenViewModifier: ViewModifier {

    @Environment(\.appDependencies.analyticsClient) var analyticsClient

    let screen: AppScreen

    func body(content: Content) -> some View {
        content
            .onAppear {
                analyticsClient.log(.screenView(screen))
            }
    }

}

public extension View {

    /// 画面が表示されたときに`screen_view`イベントを送信する
    /// - Parameter screen: 表示された画面
    /// - Note: 画面のルートとなるViewに付ける。前面に別画面を出して戻ってきた場合も再度送信される
    func trackScreenView(_ screen: AppScreen) -> some View {
        modifier(TrackScreenViewModifier(screen: screen))
    }

}
