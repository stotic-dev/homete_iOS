//
//  RouteResolverInjection.swift
//

import HomeFeature
import HometeDomain
import HometeInfrastructure
import HometeUI
import HouseworkTemplateFeature
import SettingFeature
import SwiftUI

private struct RouteResolverInjectionModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .environment(\.routeResolver, RouteResolver { route in
                switch route {
                case .cohabitantRegistration:
                    CohabitantRegistrationView()
                case .setting:
                    SettingViewScreen()
                case .houseworkTemplate:
                    HouseworkTemplateScreen.make()
                case .paywall:
                    #if os(iOS)
                    PaywallScreen()
                    #else
                    EmptyView()
                    #endif
                }
            })
    }

}

extension View {

    func routeResolverInjection() -> some View {
        modifier(RouteResolverInjectionModifier())
    }

}
