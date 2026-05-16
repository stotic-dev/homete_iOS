//
//  AdComponentResolverInjectionModifier.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import SwiftUI

#if os(iOS)
    import HometeDomain
    import HometeInfrastructure
    import HometeUI

    private struct AdComponentResolverInjectionModifier: ViewModifier {

        func body(content: Content) -> some View {
            content
                .environment(\.adComponentResolver, AdComponentResolver { type in
                    switch type {
                    case let .banner(bannerType):
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
#else
    extension View {

        func adComponentResolverInjection() -> some View {
            self
        }

    }
#endif
