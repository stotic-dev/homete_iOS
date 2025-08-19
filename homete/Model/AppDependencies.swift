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
    let appStorage: AppStorageClient
    let cohabitantClient: CohabitantClient
    
    init(
        nonceGeneratorClient: NonceGenerationClient = .previewValue,
        accountAuthClient: AccountAuthClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        appStorage: AppStorageClient = .previewValue,
        cohabitantClient: CohabitantClient = .previewValue
    ) {
        
        self.nonceGeneratorClient = nonceGeneratorClient
        self.accountAuthClient = accountAuthClient
        self.analyticsClient = analyticsClient
        self.accountInfoClient = accountInfoClient
        self.appStorage = appStorage
        self.cohabitantClient = cohabitantClient
    }
}

extension EnvironmentValues {
    
    @Entry var appDependencies: AppDependencies = .init(
        nonceGeneratorClient: .liveValue,
        accountAuthClient: .liveValue,
        analyticsClient: .liveValue,
        accountInfoClient: .liveValue,
        appStorage: .liveValue,
        cohabitantClient: .liveValue
    )
}

// MARK: Preview用の定義

extension AppDependencies {
    
    static let previewValue: Self = .init()
}
