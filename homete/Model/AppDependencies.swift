//
//  AppDependencies.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct AppDependencies {
    let nonceGeneratorRepository: NonceGenerationClient
    let accountRepository: AccountRepository
}

extension EnvironmentValues {
    
    @Entry var appDependencies: AppDependencies = .init(
        nonceGeneratorRepository: .liveValue,
        accountRepository: .liveValue
    )
}
