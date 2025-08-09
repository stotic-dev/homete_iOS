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
    
    static let previewValue: Self = .init(
        nonceGeneratorClient: .previewValue,
        accountClient: .previewValue,
        analyticsClient: .previewValue
    )
}
