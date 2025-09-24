//
//  AccountStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

@MainActor
@Observable
final class AccountStore: Storable {
    
    private(set) var account: Account = .empty
    var text: String = ""
        
    private let accountInfoClient: AccountInfoClient
    
    init(appDependencies: AppDependencies) {
        
        accountInfoClient = appDependencies.accountInfoClient
    }
    
    func loadOwnAccountData(_ auth: AccountAuthResult, fcmToken: String?) async {
        
        do {
            
            if let account = try await accountInfoClient.fetch(auth.id) {
                
                self.account = account
                
                guard let fcmToken else { return }
                await updateFcmTokenIfNeeded(fcmToken)
                return
            }
            
            let newAccount = Account.initial(auth, fcmToken)
            try await accountInfoClient.insertOrUpdate(newAccount)
            account = newAccount
        }
        catch {
            
            print("failed to fetch account info: \(error)")
        }
    }
    
    func updateFcmTokenIfNeeded(_ fcmToken: String) async {
        
        // 保持しているFCMトークンと異なるFCMトークンに変わった場合は、アカウント情報も新しいトークンに更新する
        guard account != .empty,
              account.fcmToken != fcmToken else { return }
        
        do {
            
            let updatedAccount = Account(
                id: account.id,
                displayName: account.displayName,
                fcmToken: fcmToken
            )
            try await accountInfoClient.insertOrUpdate(updatedAccount)
        }
        catch {
            
            print("failed to update fcmToken: \(error)")
        }
    }
}
