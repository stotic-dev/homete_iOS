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
                proxy.size.width
            } action: { newWidth in
                width = newWidth
            }
            .overlay {
                if let width, width > 0 {
                    BannerViewRepresentable(type: type, width: width) { height in
                        loadedInlineHeight = height
                    }
                    // 回転などで幅が変わったら、新しい幅に合うサイズで広告を読み込み直す
                    .id(width)
                }
            }
            .animation(.default, value: loadedInlineHeight)
    }

}

private extension BannerViewContainer {

    var height: CGFloat {
        guard let width, width > 0 else { return 0 }
        switch type.layout {
        case .anchored:
            // 読み込み前から広告の高さぶんの場所を確保し、読み込み後にレイアウトがずれないようにする
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
    let onReceiveAd: (CGFloat) -> Void

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

    final class Coordinator: NSObject {

        var onReceiveAd: (CGFloat) -> Void

        init(onReceiveAd: @escaping (CGFloat) -> Void) {
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
