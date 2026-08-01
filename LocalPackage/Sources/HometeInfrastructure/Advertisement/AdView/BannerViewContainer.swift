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
public struct BannerViewContainer: UIViewRepresentable {

    public typealias UIViewType = UIView
    let type: BannerType

    public init(_ type: BannerType) {
        self.type = type
    }

    public func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMobileAds)
        let banner = BannerView(adSize: type.size)
        banner.adUnitID = type.unitId
        banner.load(Request())
        banner.delegate = context.coordinator
        return banner
        #else
        return UIView()
        #endif
    }

    public func updateUIView(_: UIView, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

}

public extension BannerViewContainer {

    final class Coordinator: NSObject {

        private let parent: BannerViewContainer

        init(parent: BannerViewContainer) {
            self.parent = parent
        }

    }

}

#if canImport(GoogleMobileAds)
extension BannerViewContainer.Coordinator: BannerViewDelegate {}
#endif

#endif
