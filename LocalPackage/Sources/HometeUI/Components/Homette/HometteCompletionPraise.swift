//
//  HometteCompletionPraise.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事を完了したときに、ほめっとがほめる内容
public struct HometteCompletionPraise: Equatable, Sendable {

    /// 完了した家事の名前
    let houseworkTitle: String
    /// 担当者に配ったポイントの合計
    let point: Int
    /// セリフの種類
    let line: Line

    /// - Parameter line: 飽きにくいように、指定しなければ完了のたびにランダムに選ぶ
    public init(houseworkTitle: String, point: Int, line: Line = Line.allCases.randomElement() ?? .done) {
        self.houseworkTitle = houseworkTitle
        self.point = point
        self.line = line
    }

    public enum Line: CaseIterable, Sendable {

        case done
        case goodJob
        case allDone

    }

}

/// 家事を完了したときに、ほめっとのセリフと「+pt」の演出でほめる
///
/// 表示されたときから再生を始め、見せ終わったら`completion`を呼ぶ。完了のハーフモーダルの中で出し、
/// `completion`でモーダルを閉じる想定のため、消えるアニメーションは付けない（閉じる動きと重なるため）。
/// 触覚で手応えを返し、VoiceOverにはセリフを読み上げさせる。
public struct HometteCompletionPraisePlayer: View {

    @Environment(\.accessibilityReduceMotion) private var isReduceMotion

    let praise: HometteCompletionPraise
    let completion: () -> Void

    @State private var isAppeared = false
    @State private var isPointRaised = false

    public init(praise: HometteCompletionPraise, completion: @escaping () -> Void) {
        self.praise = praise
        self.completion = completion
    }

    public var body: some View {
        HometteCompletionPraiseView(
            praise: praise,
            isAppeared: isAppeared,
            isPointRaised: isPointRaised,
            isReduceMotion: isReduceMotion
        )
        .sensoryFeedback(.success, trigger: isAppeared) { _, newValue in
            newValue
        }
        .task {
            AccessibilityNotification.Announcement(String(localized: praise.message)).post()
            withAnimation(isReduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.4)) {
                isAppeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                isPointRaised = true
            }
            do {
                try await Task.sleep(for: .seconds(1.8))
            } catch {
                // 途中で画面から外れた場合は、終わったことにしない
                return
            }
            completion()
        }
    }

}

/// 演出のある時点の絵
///
/// 状態を外から渡すことで、Previewでは途中の1コマを固定して描けるようにしている。
struct HometteCompletionPraiseView: View {

    let praise: HometteCompletionPraise
    /// ほめっとが出ているか。出る前は`false`
    let isAppeared: Bool
    /// 「+pt」が浮き上がったか
    let isPointRaised: Bool
    /// 視差効果を減らす設定が有効か。有効なら弾ませたり浮かせたりせず、出して消すだけにする
    let isReduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            // 「+pt」はセリフに重ならないよう、ほめっとの右隣の上に置いてから浮き上がらせる
            pointLabel
                .padding(.leading, HometteView.Size.medium.height)
            HometteSpeechView(.praise, message: praise.message, size: .medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isAppeared || isReduceMotion ? 1 : 0.6, anchor: .bottomLeading)
        .opacity(isAppeared ? 1 : 0)
        // 出たときにセリフを読み上げるので、絵は読み上げない
        .accessibilityHidden(true)
    }

}

private extension HometteCompletionPraiseView {

    var pointLabel: some View {
        Text(.localized("+\(praise.point)pt", comment: "家事を完了してもらえたポイント"))
            .font(with: .number)
            .foregroundStyle(.textReward)
            .padding(.horizontal, .space8)
            .background(.fillRewardSubtle, in: Capsule())
            .offset(y: isPointRaised && !isReduceMotion ? -.space24 : .zero)
    }

}

private extension HometteCompletionPraise {

    /// ほめっとのセリフ。ほめっとの言葉なので、くだけた口調にする
    var message: LocalizedStringResource {
        switch line {
        case .done:
            .localized("やったね、\(houseworkTitle)おわり！", comment: "ほめっとのセリフ。家事の名前が入る")

        case .goodJob:
            .localized("\(houseworkTitle)、おつかれさま！", comment: "ほめっとのセリフ。家事の名前が入る")

        case .allDone:
            .localized("\(houseworkTitle)、きっちりおわったね！", comment: "ほめっとのセリフ。家事の名前が入る")
        }
    }

}

#Preview("HometteCompletionPraiseView_ポイントが浮き上がった", traits: .sizeThatFitsLayout) {
    HometteCompletionPraiseView(
        praise: .init(houseworkTitle: "洗濯", point: 20, line: .done),
        isAppeared: true,
        isPointRaised: true,
        isReduceMotion: false
    )
    .padding(.space16)
    .background(.backgroundScreen)
}

#Preview("HometteCompletionPraiseView_視差効果を減らす", traits: .sizeThatFitsLayout) {
    HometteCompletionPraiseView(
        praise: .init(houseworkTitle: "お風呂そうじ", point: 30, line: .goodJob),
        isAppeared: true,
        isPointRaised: true,
        isReduceMotion: true
    )
    .padding(.space16)
    .background(.backgroundScreen)
}

#Preview("HometteCompletionPraiseView_長い家事名", traits: .sizeThatFitsLayout) {
    HometteCompletionPraiseView(
        praise: .init(houseworkTitle: "キッチンの換気扇のフィルター交換", point: 50, line: .allDone),
        isAppeared: true,
        isPointRaised: false,
        isReduceMotion: false
    )
    .padding(.space16)
    .background(.backgroundScreen)
}
