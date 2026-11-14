//
//  ThanksFeedbackModifier.swift
//  LocalPackage
//

import SwiftUI

public extension View {

    /// ありがとうを伝えられたときに、触覚とハートの演出で手応えを返す
    ///
    /// 演出は画面全体の上に重ねて1秒ほどで消え、その間も下の画面は操作できる。
    /// - Parameter trigger: 値が変わるたびに演出を1回再生する。伝えた回数を数えて渡す想定
    func thanksFeedback(trigger: Int) -> some View {
        modifier(ThanksFeedbackModifier(trigger: trigger))
    }

}

private struct ThanksFeedbackModifier: ViewModifier {

    let trigger: Int

    /// 再生中の演出のきっかけになった値。再生していなければnil
    @State private var playingTrigger: Int?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let playingTrigger {
                    ThanksHeartBurstView {
                        // 再生中に次のありがとうが届いていたら、新しい演出を消さない
                        if self.playingTrigger == playingTrigger {
                            self.playingTrigger = nil
                        }
                    }
                    // 続けて伝えたときは、途中の演出を最初からやり直す
                    .id(playingTrigger)
                    .ignoresSafeArea()
                    // 演出の間も下の画面を操作できるようにする
                    .allowsHitTesting(false)
                }
            }
            .sensoryFeedback(.success, trigger: trigger)
            .onChange(of: trigger) {
                playingTrigger = trigger
            }
    }

}
