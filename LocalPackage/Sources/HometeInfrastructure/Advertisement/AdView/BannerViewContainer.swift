//
//  BannerViewContainer.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
import HometeDomain
import SwiftUI

#if os(iOS)
/// 配置先の幅に合わせたアダプティブサイズで広告バナーを表示する
///
/// 高さは広告のサイズから決まるので、呼び出し側で`frame(height:)`を指定しない
public struct BannerViewContainer: View {

    @State private var width: CGFloat?
    /// インライン型のバナーで、読み込んだ広告の高さ
    @State private var loadedInlineHeight: CGFloat = 0

    let type: BannerType

    public init(_ type: BannerType) {
        self.type = type
    }

    public var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .onGeometryChange(for: CGFloat.self) { proxy in
                // 小数の揺れで広告を読み込み直さないよう、整数に丸めてから比較する
                proxy.size.width.rounded(.down)
            } action: { newWidth in
                width = newWidth
                // 読み込み直す広告は高さが変わりうるので、届くまでは前の広告の高さを残さない
                loadedInlineHeight = 0
            }
            .overlay {
                if let width, width > 0 {
                    BannerViewRepresentable(type: type, width: width) { height in
                        // 後ろのコンテンツも一緒に動くよう、トランザクションごとアニメーションさせる
                        withAnimation {
                            loadedInlineHeight = height
                        }
                    }
                    // 高さ0の枠では広告を読み込めない（Invalid ad width or height）ので、広告ビュー自体には
                    // 要求したサイズの枠を渡し、見せる範囲だけを確保した高さに切り詰める
                    .frame(width: width, height: bannerViewHeight(width: width))
                    // 確保した枠からはみ出して、周りのボタンやコンテンツに広告が重ならないようにする
                    .frame(height: height, alignment: .top)
                    .clipped()
                    .allowsHitTesting(height > 0)
                    // 回転などで幅が変わったら、新しい幅に合うサイズで広告を読み込み直す
                    .id(width)
                }
            }
    }

}

private extension BannerViewContainer {

    /// 画面上に確保する高さ
    var height: CGFloat {
        guard let width, width > 0 else { return 0 }
        switch type.layout {
        case .anchored:
            // 読み込み前から広告の高さぶんの場所を確保し、読み込み後にレイアウトがずれないようにする
            // 広告が届かなかった場合も空けたままにする（AdMobの推奨する固定スペースの確保）
            #if canImport(GoogleMobileAds)
            return type.adSize(width: width).size.height
            #else
            return 0
            #endif

        case .inline:
            // 広告が届くまで高さは決まらないので、届くまでは場所を取らない
            return loadedInlineHeight
        }
    }

    /// 広告ビュー自体に渡す高さ
    func bannerViewHeight(width: CGFloat) -> CGFloat {
        #if canImport(GoogleMobileAds)
        let requestedHeight = type.adSize(width: width).size.height
        switch type.layout {
        case .anchored:
            return requestedHeight

        case .inline:
            // 届くまでは上限の高さで読み込み、届いたら実際の広告の高さに合わせる
            return loadedInlineHeight > 0 ? loadedInlineHeight : requestedHeight
        }
        #else
        return 0
        #endif
    }

}

private struct BannerViewRepresentable: UIViewRepresentable {

    let type: BannerType
    let width: CGFloat
    let onReceiveAd: @MainActor (CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMobileAds)
        let banner = BannerView(adSize: type.adSize(width: width))
        banner.adUnitID = type.unitId
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
        #else
        return UIView()
        #endif
    }

    func updateUIView(_: UIView, context: Context) {
        context.coordinator.onReceiveAd = onReceiveAd
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onReceiveAd: onReceiveAd)
    }

    @MainActor
    final class Coordinator: NSObject {

        var onReceiveAd: @MainActor (CGFloat) -> Void

        init(onReceiveAd: @escaping @MainActor (CGFloat) -> Void) {
            self.onReceiveAd = onReceiveAd
        }

    }

}

#if canImport(GoogleMobileAds)
extension BannerViewRepresentable.Coordinator: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        // インライン型は、指定した上限の範囲で実際に届いた広告のサイズがintrinsicContentSizeに入る
        onReceiveAd(bannerView.intrinsicContentSize.height)
    }

}
#endif

#endif
