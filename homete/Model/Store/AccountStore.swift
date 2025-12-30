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
    
    private(set) var account: Account?
        
    private let accountInfoClient: AccountInfoClient
        
    init(
        account: Account? = nil,
        appDependencies: AppDependencies
    ) {
        
        self.account = account
        accountInfoClient = appDependencies.accountInfoClient
    }
    
    /// アカウント情報をロードし、オンメモリにキャッシュする
    /// - Returns: ロードしたアカウント情報を返す（アカウントがない場合はnilを返す）
    @discardableResult
    func load(_ auth: AccountAuthResult) async -> Account? {
        
        do {
            
            account = try await accountInfoClient.fetch(auth.id)
        }
        catch {
            
            print("failed to fetch account info: \(error)")
        }
        
        return account
    }
    
    func registerAccount(auth: AccountAuthResult, userName: UserName) async throws -> Account {
        
        let newAccount = Account(id: auth.id, userName: userName.value, fcmToken: nil)
        try await accountInfoClient.insertOrUpdate(newAccount)
        account = newAccount
        return newAccount
    }
    
    func updateFcmTokenIfNeeded(_ fcmToken: String) async {
        
        // 保持しているFCMトークンと異なるFCMトークンに変わった場合は、アカウント情報も新しいトークンに更新する
        guard let account,
              account.fcmToken != fcmToken else { return }
        
        do {
            
            let updatedAccount = Account(
                id: account.id,
                userName: account.userName,
                fcmToken: fcmToken
            )
            try await accountInfoClient.insertOrUpdate(updatedAccount)
            self.account = updatedAccount
        }
        catch {
            
            print("failed to update fcmToken: \(error)")
        }
    }
}
