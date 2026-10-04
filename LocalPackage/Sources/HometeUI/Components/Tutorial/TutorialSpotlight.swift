//
//  TutorialSpotlight.swift
//  LocalPackage
//

import SwiftUI

/// チュートリアルでハイライトするUIの識別子
///
/// 各Featureが`extension TutorialSpotlightID`で自分のUIの識別子を定義し、
/// 対象のUIに`.tutorialSpotlightTarget(_:)`で付ける。
public struct TutorialSpotlightID: Hashable, Sendable {

    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

}

public extension View {

    /// チュートリアルでハイライトできるUIとして、位置をスポットライトに伝える
    ///
    /// スポットライトを出していない間は何もしない。そのため、本番の画面と共有しているUIに付けておいてよい。
    func tutorialSpotlightTarget(_ id: TutorialSpotlightID) -> some View {
        modifier(TutorialSpotlightTargetModifier(id: id))
    }

    /// 配下のUIを、スポットライトの切り抜きの対象から外す
    ///
    /// チュートリアル用の画面を本番の画面に重ねて出すときに、後ろに隠れた本番の画面のUIが
    /// 同じ識別子で位置を伝えてしまわないようにする。
    func excludedFromTutorialSpotlight() -> some View {
        environment(\.tutorialSpotlightFrameReporter, nil)
    }

    /// 画面を暗くして`targets`のUIだけを切り抜き、説明のカードを重ねる
    ///
    /// 対象のUIの位置は画面全体の座標で受け取るため、`TabView`やナビゲーションバーの中にある
    /// UIも切り抜ける。後ろの画面は操作できないようにし、カードのボタンだけを押せるようにする。
    /// - Parameters:
    ///   - isPresented: スポットライトを出すかどうか
    ///   - targets: 切り抜くUI。まだ表示されていないUIは切り抜かない
    ///   - cardAlignment: カードを置く位置。切り抜いたUIと重ならない位置を選ぶ
    func tutorialSpotlight(
        isPresented: Bool,
        targets: [TutorialSpotlightID],
        cardAlignment: Alignment,
        @ViewBuilder card: () -> some View
    ) -> some View {
        modifier(TutorialSpotlightModifier(
            isPresented: isPresented,
            targets: targets,
            cardAlignment: cardAlignment,
            card: card()
        ))
    }

}

// MARK: - 位置の受け渡し

/// ハイライトの対象のUIが、自分の位置をスポットライトに伝えるための窓口
///
/// スポットライトを出している間だけEnvironmentに入る。
struct TutorialSpotlightFrameReporter {

    let report: @MainActor @Sendable (TutorialSpotlightID, CGRect?) -> Void

}

extension EnvironmentValues {

    @Entry var tutorialSpotlightFrameReporter: TutorialSpotlightFrameReporter?

}

struct TutorialSpotlightTargetModifier: ViewModifier {

    @Environment(\.tutorialSpotlightFrameReporter) var reporter

    let id: TutorialSpotlightID

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                reporter?.report(id, frame)
            }
            .onDisappear {
                reporter?.report(id, nil)
            }
    }

}

// MARK: - スポットライト

struct TutorialSpotlightModifier<Card: View>: ViewModifier {

    /// ハイライトの対象のUIの位置（画面全体の座標）
    @State private var targetFrames: [TutorialSpotlightID: CGRect] = [:]

    let isPresented: Bool
    let targets: [TutorialSpotlightID]
    let cardAlignment: Alignment
    let card: Card

    func body(content: Content) -> some View {
        content
            // 対象のUIは、スポットライトが出ている間だけ位置を測る
            .environment(\.tutorialSpotlightFrameReporter, isPresented ? reporter : nil)
            .overlay {
                if isPresented {
                    TutorialSpotlightOverlay(
                        highlightedFrames: targets.compactMap { targetFrames[$0] },
                        cardAlignment: cardAlignment,
                        card: card
                    )
                    .transition(.opacity)
                }
            }
    }

    private var reporter: TutorialSpotlightFrameReporter {
        let targetFrames = $targetFrames
        return .init { id, frame in
            targetFrames.wrappedValue[id] = frame
        }
    }

}

struct TutorialSpotlightOverlay<Card: View>: View {

    /// 切り抜くUIの位置（画面全体の座標）
    let highlightedFrames: [CGRect]
    let cardAlignment: Alignment
    let card: Card

    /// 切り抜きを対象のUIより一回り大きくして、UIの縁が暗がりに埋もれないようにする
    private static var highlightPadding: CGFloat {
        .space8
    }

    private static var highlightCornerRadius: CGFloat {
        DesignSystem.Corner.radius16.rawValue
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let holes = holes(in: proxy.frame(in: .global))
                ZStack {
                    // 後ろの画面を触らせないよう、切り抜いた部分も含めてタップを受け止める
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {}
                    SpotlightDimmingShape(holes: holes, cornerRadius: Self.highlightCornerRadius)
                        .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))
                        .allowsHitTesting(false)
                    ForEach(Array(holes.enumerated()), id: \.offset) { _, hole in
                        RoundedRectangle(cornerRadius: Self.highlightCornerRadius)
                            .stroke(.white.opacity(0.8), lineWidth: 2)
                            .frame(width: hole.width, height: hole.height)
                            .position(x: hole.midX, y: hole.midY)
                            .allowsHitTesting(false)
                    }
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            card
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: cardAlignment)
        }
        .animation(.easeInOut, value: highlightedFrames)
    }

    /// 切り抜く範囲を、このViewの座標に直して返す
    private func holes(in overlayFrame: CGRect) -> [CGRect] {
        highlightedFrames.map {
            $0.offsetBy(dx: -overlayFrame.minX, dy: -overlayFrame.minY)
                .insetBy(dx: -Self.highlightPadding, dy: -Self.highlightPadding)
        }
    }

}

/// 全体を塗りつぶし、`holes`の部分だけを角丸で抜く形
///
/// 偶奇規則（`eoFill`）で塗ると、重ねた角丸の部分が抜ける。
struct SpotlightDimmingShape: Shape {

    let holes: [CGRect]
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        for hole in holes {
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
        return path
    }

}

#if DEBUG
#Preview("TutorialSpotlightOverlay") {
    TutorialSpotlightOverlay(
        highlightedFrames: [CGRect(x: 24, y: 160, width: 200, height: 80)],
        cardAlignment: .bottom,
        card: Text("説明のカード")
            .frame(maxWidth: .infinity)
            .sectionCardStyle()
    )
}
#endif
