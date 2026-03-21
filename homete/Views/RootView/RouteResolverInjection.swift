//
//  RouteResolverInjection.swift
//  homete
//

import HometeDomain
import HometeUI
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
                    SettingView()
                }
            })
    }
}

extension View {

    func routeResolverInjection() -> some View {
        modifier(RouteResolverInjectionModifier())
    }
}
