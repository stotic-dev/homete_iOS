//
//  AdComponentResolverInjectionModifier.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import HometeInfrastructure
import SwiftUI

private struct AdComponentResolverInjectionModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .environment(\.adComponentResolver, AdComponentResolver { type in
                switch type {
                case .banner(let bannerType):
                    BannerViewContainer(bannerType)
                }
            })
    }
}

extension View {

    func adComponentResolverInjection() -> some View {
        modifier(AdComponentResolverInjectionModifier())
    }
}
