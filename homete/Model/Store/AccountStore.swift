//
//  AccountStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

@MainActor
@Observable
final class AccountStore {
    var account: Account?
    private let accountRepository: AccountRepository
    private let listener: AccountListenerStream
    
    init(appDependencies: AppDependencies) {
        self.accountRepository = appDependencies.accountRepository
        self.listener = accountRepository.makeListener()
        
        Task {
            await listen()
        }
    }
}

private extension AccountStore {
    
    func listen() async {
        for await value in listener.values {
            account = value
        }
    }
}

extension EnvironmentValues {
    
    @Entry var accountStore: AccountStore?
}
