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
    
    var account: Account = .empty
    var isLoadingInfo: Bool { account == .empty }
        
    private let accountAuthClient: AccountAuthClient
    private let accountInfoClient: AccountInfoClient
    private let analyticsClient: AnalyticsClient
    
    init(appDependencies: AppDependencies) {
        
        accountAuthClient = appDependencies.accountAuthClient
        accountInfoClient = appDependencies.accountInfoClient
        analyticsClient = appDependencies.analyticsClient
    }
    
    func setAccount(_ auth: AccountAuthResult) async {
        
        do {
            
            if let account = try await accountInfoClient.fetch(auth.id) {
                
                self.account = account
                return
            }
            
            let newAccount = Account.initial(auth)
            try await accountInfoClient.insertOrUpdate(newAccount)
            account = newAccount
        }
        catch {
            
            print("failed to fetch account info: \(error)")
        }
    }
    
    func logOut() {
        
        do {
            
            try accountAuthClient.signOut()
            analyticsClient.log(.logout())
        }
        catch {
            
            print("occurred error: \(error)")
        }
    }
}
