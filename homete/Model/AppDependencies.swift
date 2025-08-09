//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct AppDependencies {
    let nonceGeneratorClient: NonceGenerationClient
    let accountAuthClient: AccountAuthClient
    let analyticsClient: AnalyticsClient
    let accountInfoClient: AccountInfoClient
    
    init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue
    ) {
        
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.accountInfoClient = accountInfoClient
    }
}

extension EnvironmentValues {
    
    @Entry var appDependencies: AppDependencies = .init(
        nonceGeneratorClient: .liveValue,
        accountAuthClient: .liveValue,
        analyticsClient: .liveValue,
        accountInfoClient: .liveValue
    )
}

// MARK: Preview用の定義

extension AppDependencies {
    
    static let previewValue: Self = .init()
}
