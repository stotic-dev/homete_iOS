//
//  HometteView.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// イメージキャラクター「ほめっと」の表情・ポーズ
///
/// 使う場面はADR-0041とIssue #403の表に合わせる。
public enum HometteExpression: CaseIterable, Sendable {

    /// ふつう。ホームのあいさつ、初回起動
    case normal
    /// ほめる。家事の完了、+ptの演出
    case praise
    /// ありがとう。ありがとうの受信
    case thanks
    /// おつかれ。今日の家事がぜんぶ終わったとき
    case rest
    /// さそう。家事やパートナーが未登録、貢献度のデータがないとき
    case cheer
    /// こまった。読み込みエラー
    case puzzled
    /// てをふる。ログイン、オンボーディングの最初
    case wave
    /// ハートをわたす。ありがとうを送る画面
    case holdHeart
    /// あんないする。オンボーディングの案内、機能紹介
    case point

}

/// イメージキャラクター「ほめっと」を決まった大きさで表示する
///
/// 画像は拡大しない前提でHEICの@2x / @3xを入れているため、大きさは`Size`から選ぶ（素材の1倍は240×256pt）。
/// 絵は飾りなので、VoiceOverでは読み上げない。伝えたいことは隣の文言か吹き出し（`HometteSpeechView`）に書く。
public struct HometteView: View {

    let expression: HometteExpression
    let size: Size

    public init(_ expression: HometteExpression, size: Size = .medium) {
        self.expression = expression
        self.size = size
    }

    public var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(height: size.height)
            .accessibilityHidden(true)
    }

}

public extension HometteView {

    enum Size: Sendable {

        /// カードの中や吹き出しの横に添える
        case small
        /// 空状態やシートの主役にする
        case medium
        /// ログインや登録完了など、画面いっぱいの主役にする
        case large

        var height: CGFloat {
            switch self {
            case .small: 64
            case .medium: 128
            case .large: 192
            }
        }

    }

}

// MARK: 表示の属性

private extension HometteView {

    var image: HometeImage {
        switch expression {
        case .normal: .homette_normal
        case .praise: .homette_praise
        case .thanks: .homette_thanks
        case .rest: .homette_rest
        case .cheer: .homette_cheer
        case .puzzled: .homette_puzzled
        case .wave: .homette_wave
        case .holdHeart: .homette_holdHeart
        case .point: .homette_point
        }
    }

}

#Preview("HometteView_表情", traits: .sizeThatFitsLayout) {
    LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: .space16) {
        ForEach(HometteExpression.allCases, id: \.self) { expression in
            HometteView(expression)
        }
    }
    .padding(.space16)
}

#Preview("HometteView_大きさ", traits: .sizeThatFitsLayout) {
    HStack(alignment: .bottom, spacing: .space16) {
        HometteView(.normal, size: .small)
        HometteView(.normal, size: .medium)
        HometteView(.normal, size: .large)
    }
    .padding(.space16)
}
