//
//  CohabitantStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import SwiftUI

@MainActor
@Observable
final class CohabitantStore {
    
    private(set) var members: Set<CohabitantMember>
    private var listenerTask: Task<Void, Never>?
    
    private let cohabitantListenerKey = "cohabitantListenerKey"
    
    // MARK: Dependencies
    
    private let cohabitantClient: CohabitantClient
    private let accountInfoClient: AccountInfoClient
    
    init(
        members: Set<CohabitantMember> = [],
        appDependencies: AppDependencies = .previewValue
    ) {
        self.members = members
        cohabitantClient = appDependencies.cohabitantClient
        accountInfoClient = appDependencies.accountInfoClient
    }
    
    func addSnapshotListenerIfNeeded(_ cohabitantId: String) async {
        
        // すでに監視中の場合は何もしない
        if let listenerTask { return }
        
        let stream = await cohabitantClient.addSnapshotListener(
            cohabitantListenerKey,
            cohabitantId
        )
        
        listenerTask = Task {
            
            for await cohabitantDataList in stream {
                
                guard let cohabitantData = cohabitantDataList.first else { return }
                let filteredMembers = cohabitantData.members.filter { member in
                    return members.contains { $0.id == member }
                }
                
                for member in filteredMembers {
                    
                    do {
                        
                        guard let account = try await accountInfoClient.fetch(member) else {
                            
                            print("Not found account(cohabitantId: \(cohabitantId), userId: \(member))")
                            continue
                        }
                        members.insert(.init(id: member, userName: account.userName))
                    } catch {
                        
                        print("error occurred: \(error)")
                    }
                }
            }
        }
    }
    
    func removeSnapshotListener() async {
        
        listenerTask = nil
        await cohabitantClient.removeSnapshotListener(cohabitantListenerKey)
    }
}
