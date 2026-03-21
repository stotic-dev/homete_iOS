//
//  RouteResolverInjection.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

private struct RouteResolverInjectionModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .environment(\.routeResolver, .init { route in
                switch route {
                case .houseworkDetail(let item):
                    return AnyView(HouseworkDetailView(item: item))
                case .houseworkApproval(let item):
                    return AnyView(HouseworkApprovalView(item: item))
                case .cohabitantRegistration:
                    return AnyView(CohabitantRegistrationView())
                case .setting:
                    return AnyView(SettingView())
                }
            })
    }
}

extension View {

    func routeResolverInjection() -> some View {
        modifier(RouteResolverInjectionModifier())
    }
}
