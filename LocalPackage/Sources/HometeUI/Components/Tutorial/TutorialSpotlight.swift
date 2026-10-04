//
//  TutorialSpotlight.swift
//  LocalPackage
//

import Observation
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
    /// スポットライトを出していない間は伝えない。出す前から表示されていたUIも、出した時点で
    /// 最後の位置を伝える。本番の画面と共有しているUIに付けておいてよい。
    func tutorialSpotlightTarget(_ id: TutorialSpotlightID) -> some View {
        modifier(TutorialSpotlightTargetModifier(id: id))
    }

    /// 説明のカードを置いてよい範囲として、このViewの位置をスポットライトに伝える
    ///
    /// タブの中の画面に付けると、カードがタブバーに重ならないようになる。
    /// 付けていなければ、スポットライトを重ねたViewのセーフエリアの中に置く。
    func tutorialSpotlightCardArea() -> some View {
        modifier(TutorialSpotlightTargetModifier(id: .cardArea))
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
    /// UIも切り抜ける。カードは、切り抜いたUIの上下のうち空いている方に置く。
    /// 後ろの画面は操作できないようにし、カードのボタンだけを押せるようにする。
    /// - Parameters:
    ///   - isPresented: スポットライトを出すかどうか
    ///   - targets: 切り抜くUI。まだ表示されていないUIは切り抜かない
    func tutorialSpotlight(
        isPresented: Bool,
        targets: [TutorialSpotlightID],
        @ViewBuilder card: () -> some View
    ) -> some View {
        modifier(TutorialSpotlightModifier(
            isPresented: isPresented,
            targets: targets,
            card: card()
        ))
    }

}

// MARK: - 位置の受け渡し

extension TutorialSpotlightID {

    /// カードを置いてよい範囲
    static let cardArea = Self("tutorial_spotlight_card_area")

}

/// ハイライトの対象のUIの位置（画面全体の座標）を集める
@MainActor
@Observable
final class TutorialSpotlightFrameStore {

    private(set) var frames: [TutorialSpotlightID: CGRect] = [:]

    func update(_ id: TutorialSpotlightID, frame: CGRect?) {
        frames[id] = frame
    }

}

/// ハイライトの対象のUIが、自分の位置をスポットライトに伝えるための窓口
///
/// スポットライトを出している間だけEnvironmentに入る。
struct TutorialSpotlightFrameReporter {

    let store: TutorialSpotlightFrameStore

    /// スポットライトを出し直したことを見分けるための値
    var identity: ObjectIdentifier {
        ObjectIdentifier(store)
    }

}

extension EnvironmentValues {

    @Entry var tutorialSpotlightFrameReporter: TutorialSpotlightFrameReporter?

}

struct TutorialSpotlightTargetModifier: ViewModifier {

    @Environment(\.tutorialSpotlightFrameReporter) var reporter

    /// 最後に測った位置
    @State private var frame: CGRect?

    let id: TutorialSpotlightID

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newFrame in
                frame = newFrame
                reporter?.store.update(id, frame: newFrame)
            }
            // スポットライトを出す前から表示されていたUIは、位置が変わらず上の`action`が呼ばれないため、
            // 出した時点で最後に測った位置を伝える
            .onChange(of: reporter?.identity) {
                reporter?.store.update(id, frame: frame)
            }
            .onDisappear {
                reporter?.store.update(id, frame: nil)
            }
    }

}

// MARK: - スポットライト

struct TutorialSpotlightModifier<Card: View>: ViewModifier {

    @State private var frameStore = TutorialSpotlightFrameStore()

    let isPresented: Bool
    let targets: [TutorialSpotlightID]
    let card: Card

    func body(content: Content) -> some View {
        content
            // 対象のUIは、スポットライトが出ている間だけ位置を伝える
            .environment(\.tutorialSpotlightFrameReporter, isPresented ? .init(store: frameStore) : nil)
            .overlay {
                if isPresented {
                    TutorialSpotlightOverlay(
                        highlightedFrames: targets.compactMap { frameStore.frames[$0] },
                        cardArea: frameStore.frames[.cardArea],
                        card: card
                    )
                    .transition(.opacity)
                }
            }
    }

}

struct TutorialSpotlightOverlay<Card: View>: View {

    /// 切り抜くUIの位置（画面全体の座標）
    let highlightedFrames: [CGRect]
    /// カードを置いてよい範囲（画面全体の座標）。`nil`ならこのViewのセーフエリアの中に置く
    let cardArea: CGRect?
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
                dimmingLayer(holes: holes(in: proxy.frame(in: .global)))
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            GeometryReader { proxy in
                cardLayer(in: proxy.frame(in: .global))
            }
        }
        .animation(.easeInOut, value: highlightedFrames)
    }

}

private extension TutorialSpotlightOverlay {

    func dimmingLayer(holes: [CGRect]) -> some View {
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

    /// - Parameter layerFrame: カードを描くViewの位置（画面全体の座標）
    func cardLayer(in layerFrame: CGRect) -> some View {
        let area = cardArea ?? layerFrame
        return card
            .padding(.space16)
            .frame(
                width: area.width,
                height: area.height,
                alignment: placesCardBelow(in: area) ? .bottom : .top
            )
            .position(x: area.midX - layerFrame.minX, y: area.midY - layerFrame.minY)
    }

    /// 切り抜く範囲を、`overlayFrame`の中の座標に直して返す
    func holes(in overlayFrame: CGRect) -> [CGRect] {
        highlightedFrames.map {
            $0.offsetBy(dx: -overlayFrame.minX, dy: -overlayFrame.minY)
                .insetBy(dx: -Self.highlightPadding, dy: -Self.highlightPadding)
        }
    }

    /// 切り抜いたUIの下の方が空いていれば、カードを下に置く
    ///
    /// どちらにも収まらない小さい画面では重なるが、空きの広い方に置いて隠れる範囲を減らす。
    func placesCardBelow(in area: CGRect) -> Bool {
        let highlighted = highlightedFrames.reduce(CGRect.null) { $0.union($1) }
        guard !highlighted.isNull else { return true }

        let spaceAbove = highlighted.minY - area.minY
        let spaceBelow = area.maxY - highlighted.maxY
        return spaceBelow >= spaceAbove
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
#Preview("TutorialSpotlightOverlay_上を切り抜く") {
    TutorialSpotlightOverlay(
        highlightedFrames: [CGRect(x: 24, y: 160, width: 200, height: 80)],
        cardArea: nil,
        card: Text("説明のカード")
            .frame(maxWidth: .infinity)
            .sectionCardStyle()
    )
}

#Preview("TutorialSpotlightOverlay_下を切り抜く") {
    TutorialSpotlightOverlay(
        highlightedFrames: [CGRect(x: 240, y: 560, width: 64, height: 64)],
        cardArea: nil,
        card: Text("説明のカード")
            .frame(maxWidth: .infinity)
            .sectionCardStyle()
    )
}
#endif
