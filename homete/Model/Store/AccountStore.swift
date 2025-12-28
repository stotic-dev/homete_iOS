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
    
    private(set) var account: Account = .empty
        
    private let accountInfoClient: AccountInfoClient
        
    init(appDependencies: AppDependencies) {
        
        accountInfoClient = appDependencies.accountInfoClient
    }
    
    /// アカウント情報をロードする
    /// - Returns: アカウント作成済みかどうかを返す
    @discardableResult
    func load(_ auth: AccountAuthResult) async -> Bool {
        
        do {
            
            account = try await accountInfoClient.fetch(auth.id) ?? .empty
        }
        catch {
            
            print("failed to fetch account info: \(error)")
        }
        
        return account != .empty
    }
    
    func registerAccount(auth: AccountAuthResult, userName: UserName) async throws {
        
        let newAccount = Account(id: auth.id, userName: userName.value, fcmToken: nil)
        try await accountInfoClient.insertOrUpdate(newAccount)
        account = newAccount
    }
    
    func updateFcmTokenIfNeeded(_ fcmToken: String) async {
        
        // 保持しているFCMトークンと異なるFCMトークンに変わった場合は、アカウント情報も新しいトークンに更新する
        guard account != .empty,
              account.fcmToken != fcmToken else { return }
        
        do {
            
            let updatedAccount = Account(
                id: account.id,
                userName: account.userName,
                fcmToken: fcmToken
            )
            try await accountInfoClient.insertOrUpdate(updatedAccount)
        }
        catch {
            
            print("failed to update fcmToken: \(error)")
        }
    }
}
