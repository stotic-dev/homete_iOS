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
                    // 確保した枠からはみ出して、周りのボタンやコンテンツに広告が重ならないようにする
                    .frame(width: width, height: height)
                    .clipped()
                    // 回転などで幅が変わったら、新しい幅に合うサイズで広告を読み込み直す
                    .id(width)
                }
            }
    }

}

private extension BannerViewContainer {

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
