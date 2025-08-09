//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct AppDependencies {
    let nonceGeneratorClient: NonceGenerationClient
    let accountClient: AccountClient
    let analyticsClient: AnalyticsClient
    
    init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountClient: AccountClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) {
        
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountClient = accountClient
        self.analyticsClient = analyticsClient
    }
}

extension EnvironmentValues {
    
    @Entry var appDependencies: AppDependencies = .init(
        nonceGeneratorClient: .liveValue,
        accountClient: .liveValue,
        analyticsClient: .liveValue
    )
}

// MARK: Preview用の定義

extension AppDependencies {
    
    static let previewValue: Self = .init()
}
