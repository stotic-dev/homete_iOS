//
//  HometteCompletionPraise.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事を完了したときに、ほめっとがほめる内容
public struct HometteCompletionPraise: Hashable, Sendable {

    /// 何を完了したか
    let subject: Subject
    /// 担当者に配ったポイントの合計
    let point: Int
    /// セリフの種類
    let line: Line

    /// 1件の家事を完了したときにほめる
    /// - Parameter line: 飽きにくいように、指定しなければ完了のたびにランダムに選ぶ
    public init(houseworkTitle: String, point: Int, line: Line = Line.allCases.randomElement() ?? .done) {
        subject = .housework(title: houseworkTitle)
        self.point = point
        self.line = line
    }

    /// まとめて完了したときに、件数でほめる
    /// - Parameter line: 飽きにくいように、指定しなければ完了のたびにランダムに選ぶ
    public init(completedCount: Int, point: Int, line: Line = Line.allCases.randomElement() ?? .done) {
        subject = .count(completedCount)
        self.point = point
        self.line = line
    }

    enum Subject: Hashable {

        /// 1件の家事。家事の名前でほめる
        case housework(title: String)
        /// まとめて完了した家事の件数
        case count(Int)

    }

    public enum Line: CaseIterable, Sendable {

        case done
        case goodJob
        case allDone

    }

}

public extension View {

    /// 家事を完了したときに、ほめっとのセリフと「+pt」の演出を画面の下に重ねてほめる
    ///
    /// 完了のハーフモーダルを通らない操作（まとめて完了など）で使う。演出は2秒ほどでふわっと消え、
    /// その間も下の画面は操作できる。
    /// - Parameter praise: 値が入ると演出を再生し、終わると`nil`に戻す
    func completionPraise(_ praise: Binding<HometteCompletionPraise?>) -> some View {
        modifier(CompletionPraiseModifier(praise: praise))
    }

}

private struct CompletionPraiseModifier: ViewModifier {

    @Binding var praise: HometteCompletionPraise?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let praise {
                    HometteCompletionPraisePlayer(praise: praise) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.praise = nil
                        }
                    }
                    // 続けて完了したときは、途中の演出を最初からやり直す
                    .id(praise)
                    .padding(.horizontal, .space16)
                    .padding(.bottom, .space24)
                    .transition(.opacity)
                    // 演出の間も下の画面を操作できるようにする
                    .allowsHitTesting(false)
                }
            }
    }

}

/// 家事を完了したときに、ほめっとのセリフと「+pt」の演出でほめる
///
/// 表示されたときから再生を始め、見せ終わったら`completion`を呼ぶ。消えるアニメーションは付けないので、
/// 完了のハーフモーダルの中ではモーダルを閉じ、画面に重ねるときは呼び出し側で消し方を決める。
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
        switch subject {
        case let .housework(title):
            houseworkMessage(title: title)

        case let .count(count):
            countMessage(count: count)
        }
    }

    func houseworkMessage(title houseworkTitle: String) -> LocalizedStringResource {
        switch line {
        case .done:
            .localized("やったね、\(houseworkTitle)おわり！", comment: "ほめっとのセリフ。家事の名前が入る")

        case .goodJob:
            .localized("\(houseworkTitle)、おつかれさま！", comment: "ほめっとのセリフ。家事の名前が入る")

        case .allDone:
            .localized("\(houseworkTitle)、きっちりおわったね！", comment: "ほめっとのセリフ。家事の名前が入る")
        }
    }

    func countMessage(count: Int) -> LocalizedStringResource {
        switch line {
        case .done:
            .localized("やったね、\(count)件おわり！", comment: "ほめっとのセリフ。まとめて完了した家事の件数が入る")

        case .goodJob:
            .localized("\(count)件、おつかれさま！", comment: "ほめっとのセリフ。まとめて完了した家事の件数が入る")

        case .allDone:
            .localized("\(count)件、きっちりおわったね！", comment: "ほめっとのセリフ。まとめて完了した家事の件数が入る")
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

#Preview("HometteCompletionPraiseView_まとめて完了", traits: .sizeThatFitsLayout) {
    HometteCompletionPraiseView(
        praise: .init(completedCount: 3, point: 60, line: .done),
        isAppeared: true,
        isPointRaised: true,
        isReduceMotion: false
    )
    .padding(.space16)
    .background(.backgroundScreen)
}
