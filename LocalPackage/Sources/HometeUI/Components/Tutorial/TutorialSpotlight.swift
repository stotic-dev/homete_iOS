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

/// スポットライトの説明のカードを置く場所
public enum TutorialSpotlightCardPlacement: Sendable {

    /// 切り抜いたUIの上下のうち、空いている方に置く
    case automatic
    /// 切り抜いたUIの上下の空きに関わらず、上に置く
    case top
    /// 切り抜いたUIの上下の空きに関わらず、下に置く
    case bottom

}

public extension View {

    /// チュートリアルでハイライトできるUIとして、位置をスポットライトに伝える
    ///
    /// スポットライトを出していない間は伝えない。出す前から表示されていたUIも、出した時点で
    /// 最後の位置を伝える。本番の画面と共有しているUIに付けておいてよい。
    /// - Parameter id: `nil`なら位置を伝えない。一覧の中の特定の行だけを対象にするときに使う
    func tutorialSpotlightTarget(_ id: TutorialSpotlightID?) -> some View {
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
    ///   - cardPlacement: カードを置く場所。切り抜いたUIが大きく、見せたい部分がカードに隠れるときに指定する
    func tutorialSpotlight(
        isPresented: Bool,
        targets: [TutorialSpotlightID],
        cardPlacement: TutorialSpotlightCardPlacement = .automatic,
        @ViewBuilder card: () -> some View
    ) -> some View {
        modifier(TutorialSpotlightModifier(
            isPresented: isPresented,
            targets: targets,
            cardPlacement: cardPlacement,
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
    /// 最後に位置を伝えてきたUI
    @ObservationIgnored private var owners: [TutorialSpotlightID: UUID] = [:]

    /// - Parameters:
    ///   - frame: `nil`なら、そのUIが消えたものとして位置を消す
    ///   - owner: 位置を伝えてきたUI。同じ識別子のUIが作り直されたときに、
    ///     古いUIが消えた知らせで新しいUIの位置を消さないようにする
    func update(_ id: TutorialSpotlightID, frame: CGRect?, owner: UUID) {
        if let frame {
            frames[id] = frame
            owners[id] = owner
            return
        }
        guard owners[id] == owner else { return }

        frames[id] = nil
        owners[id] = nil
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

    /// 最後に測った位置（画面全体の座標）
    @State private var frame: CGRect?
    /// SwiftUIの上での位置。変わったら、画面全体の座標で測り直すきっかけにする
    @State private var layoutFrame: CGRect?
    /// 位置を伝えるときに、どのUIからの知らせかを見分けるための値
    @State private var owner = UUID()

    /// `nil`なら位置を伝えない
    let id: TutorialSpotlightID?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newFrame in
                layoutFrame = newFrame
                #if !os(iOS)
                update(newFrame)
                #endif
            }
        #if os(iOS)
            // ナビゲーションバーの項目は、タブが選ばれる前などウィンドウに載る前に測られることがあり、
            // そのあと位置が変わらないと測り直されない。ウィンドウに載ったときにもUIKitで測り直す
            .background {
                TutorialSpotlightWindowFrameReader(trigger: layoutFrame) { newFrame in
                    update(newFrame)
                }
            }
        #endif
            // スポットライトを出す前から表示されていたUIは、位置が変わらず上の`action`が呼ばれないため、
            // 出した時点で最後に測った位置を伝える
            .onChange(of: reporter?.identity) {
                report(frame)
            }
            .onDisappear {
                // 表示し直したときに、同じ位置でも伝え直すようにする
                frame = nil
                report(nil)
            }
    }

    private func update(_ newFrame: CGRect) {
        guard newFrame != frame else { return }

        frame = newFrame
        report(newFrame)
    }

    private func report(_ frame: CGRect?) {
        guard let id else { return }

        reporter?.store.update(id, frame: frame, owner: owner)
    }

}

// MARK: - スポットライト

struct TutorialSpotlightModifier<Card: View>: ViewModifier {

    @State private var frameStore = TutorialSpotlightFrameStore()

    let isPresented: Bool
    let targets: [TutorialSpotlightID]
    let cardPlacement: TutorialSpotlightCardPlacement
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
                        cardPlacement: cardPlacement,
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
    var cardPlacement: TutorialSpotlightCardPlacement = .automatic
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

    /// カードを下に置くかどうか。置き場所の指定が無ければ、切り抜いたUIの下の方が空いているときに下に置く
    ///
    /// どちらにも収まらない小さい画面では重なるが、空きの広い方に置いて隠れる範囲を減らす。
    func placesCardBelow(in area: CGRect) -> Bool {
        switch cardPlacement {
        case .top:
            return false

        case .bottom:
            return true

        case .automatic:
            break
        }
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
