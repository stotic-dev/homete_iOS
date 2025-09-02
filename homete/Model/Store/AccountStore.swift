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
        
    private let accountInfoClient: AccountInfoClient
    
    init(appDependencies: AppDependencies) {
        
        accountInfoClient = appDependencies.accountInfoClient
    }
    
    func setInitialAccountIfNeeded(_ auth: AccountAuthResult) async {
        
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
}
