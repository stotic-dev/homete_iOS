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
    
    private let accountClient: AccountClient
    private let analyticsClient: AnalyticsClient
    private let listener: AccountListenerStream
    
    init(appDependencies: AppDependencies) {
        
        accountClient = appDependencies.accountClient
        analyticsClient = appDependencies.analyticsClient
        listener = accountClient.makeListener()
        
        Task {
            
            await listen()
        }
    }
    
    func login(_ signInResult: SignInWithAppleResult) async throws {
        
        do {
            
            let account = try await accountClient.signIn(signInResult.tokenId, signInResult.nonce)
            analyticsClient.setId(account.id)
            analyticsClient.log(.login(isSuccess: true))
        }
        catch {
            
            analyticsClient.log(.login(isSuccess: false))
            throw error
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
