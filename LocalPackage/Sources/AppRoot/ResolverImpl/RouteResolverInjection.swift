//
//  RouteResolverInjection.swift
//

import CohabitantRegistrationFeature
import FrequentHouseworkFeature
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
                case let .cohabitantJoin(token):
                    CohabitantJoinView(token: token)
                case .setting:
                    SettingViewScreen()
                case .houseworkTemplate:
                    HouseworkTemplateScreen.make()
                case .frequentHouseworkManagement:
                    FrequentHouseworkManagementScreen()
                case .paywall:
                    // PaywallScreenはHometeInfrastructureにあり、HometeUIに依存しない。
                    // 計測のためだけに依存を増やさず、画面を組み立てるここでModifierを付ける
                    PaywallScreen()
                        .trackScreenView(.paywall)
                #if DEBUG
                case .debugOnboarding:
                    DebugOnboardingScreen()
                case .debugCohabitantRegistration:
                    DebugCohabitantRegistrationScreen()
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
