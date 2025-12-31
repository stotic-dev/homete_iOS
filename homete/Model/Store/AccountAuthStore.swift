//
//  AccountAuthStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import SwiftUI

@MainActor
@Observable
final class AccountAuthStore {
    
    private(set) var currentAuth: AccountAuthInfo
    
    private let accountAuthClient: AccountAuthClient
    private let analyticsClient: AnalyticsClient
    private let listener: AccountListenerStream
    
    init(
        appDependencies: AppDependencies,
        currentAuth: AccountAuthInfo = .initial
    ) {
       
        accountAuthClient = appDependencies.accountAuthClient
        analyticsClient = appDependencies.analyticsClient
        self.currentAuth = currentAuth
        
        listener = accountAuthClient.makeListener()
        
        Task {
            
            await listen()
        }
    }
    
    func login(_ signInResult: SignInWithAppleResult) async throws {
        
        do {
            
            let authInfo = try await accountAuthClient.signIn(signInResult.tokenId, signInResult.nonce)
            analyticsClient.setId(authInfo.id)
            analyticsClient.log(.login(isSuccess: true))
        }
        catch {
            
            analyticsClient.log(.login(isSuccess: false))
            throw error
        }
    }
    
    func logOut() {
        
        do {
            
            currentAuth = .init(result: nil, alreadyLoadedAtInitiate: true)
            try accountAuthClient.signOut()
            analyticsClient.log(.logout())
        }
        catch {
            
            print("occurred error: \(error)")
        }
    }
}

private extension AccountAuthStore {
    
    func listen() async {
        
        for await value in listener.values {
            
            currentAuth = .init(result: value, alreadyLoadedAtInitiate: true)
            print("currentAuth snapshot: \(String(describing: currentAuth))")
        }
    }
}
