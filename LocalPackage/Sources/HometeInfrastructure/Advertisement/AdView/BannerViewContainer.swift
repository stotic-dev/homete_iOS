//
//  BannerViewContainer.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import GoogleMobileAds
import HometeDomain
import SwiftUI

public struct BannerViewContainer: UIViewRepresentable {

    public typealias UIViewType = BannerView
    let type: BannerType

    public init(_ type: BannerType) {
        self.type = type
    }

    public func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: type.size)
        banner.adUnitID = type.unitId
        banner.load(Request())
        banner.delegate = context.coordinator
        return banner
    }

    public func updateUIView(_: BannerView, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

}

public extension BannerViewContainer {

    final class Coordinator: NSObject, BannerViewDelegate {

        private let parent: BannerViewContainer

        init(parent: BannerViewContainer) {
            self.parent = parent
        }

    }

}
