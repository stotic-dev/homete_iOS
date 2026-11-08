//
//  TutorialSpotlightScroll.swift
//  LocalPackage
//

import SwiftUI

public extension View {

    /// `ScrollView`の中にある、チュートリアルでハイライトできるUIとして位置をスポットライトに伝える
    ///
    /// `tutorialSpotlightTarget(_:)`と同じく位置を伝え、ハイライトされたときに`scrollsToTutorialSpotlightTarget()`を付けた
    /// `ScrollView`がこのUIまでスクロールする。入力欄が増えて画面の下に押し出されるような、端末の大きさによって
    /// 画面の外に出るUIに付ける。`List`の行には付けない（行の識別子を上書きしてしまうため）。
    func tutorialSpotlightScrollTarget(_ id: TutorialSpotlightID) -> some View {
        tutorialSpotlightTarget(id)
            .id(id)
    }

    /// ハイライトされた`tutorialSpotlightScrollTarget(_:)`のUIが見えるように、この`ScrollView`をスクロールする
    ///
    /// `ScrollView`に付ける。スポットライトの対象が変わったときと、スポットライトを出している間に
    /// この`ScrollView`が表示されたときにスクロールする。
    func scrollsToTutorialSpotlightTarget() -> some View {
        modifier(TutorialSpotlightScrollModifier())
    }

}

struct TutorialSpotlightScrollModifier: ViewModifier {

    @Environment(\.tutorialSpotlightActiveTargets) var targets

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: targets, initial: true) { _, newTargets in
                    // この`ScrollView`の中に無い識別子なら、何も起きない
                    guard let target = newTargets.first else { return }
                    withAnimation {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
        }
    }

}
