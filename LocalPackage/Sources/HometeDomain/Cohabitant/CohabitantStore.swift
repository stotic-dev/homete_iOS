//
//  CohabitantStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import Observation
import SwiftUI

@MainActor
@Observable
public final class CohabitantStore {

    public private(set) var members: CohabitantMemberList
    /// スナップショットリスナーの購読状態
    public private(set) var loadState: ListenerLoadState = .loading
    private var listenerTask: Task<Void, Never>?

    private let cohabitantListenerKey = "cohabitantListenerKey"

    // MARK: Dependencies

    private let cohabitantClient: CohabitantClient
    private let accountInfoClient: AccountInfoClient

    public init(
        members: Set<CohabitantMember> = [],
        ownId: String = "",
        cohabitantClient: CohabitantClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue
    ) {
        self.members = .init(value: members, ownId: ownId)
        self.cohabitantClient = cohabitantClient
        self.accountInfoClient = accountInfoClient
    }

    public func addSnapshotListenerIfNeeded(_ cohabitantId: String) async {
        // すでに監視中の場合は何もしない
        if listenerTask != nil { return }

        loadState = .loading
        let stream = await cohabitantClient.addSnapshotListener(
            cohabitantListenerKey,
            cohabitantId
        )

        listenerTask = Task {
            do {
                for try await cohabitantData in stream {
                    guard let cohabitantData else { continue }

                    for member in self.members.missingMemberIds(from: .init(cohabitantData.members)) {
                        do {
                            guard let account = try await accountInfoClient.fetch(member) else {
                                print("Not found account(cohabitantId: \(cohabitantId), userId: \(member))")
                                continue
                            }
                            members.insert(.init(id: member, userName: account.userName))
                            print("loaded cohabitant members: \(members)")
                        } catch {
                            print("error occurred: \(error)")
                        }
                    }

                    // 初回のデータをロード完了したらその旨の状態にする
                    loadState = .loaded
                }

                print("finish listening cohabitant snapshot.")
            } catch {
                // リスナーが購読を継続できなくなった場合は失敗状態にし、再購読できるようにタスクを解放する
                print("error occurred at cohabitant snapshot listener: \(error)")
                loadState = .failed(DomainError.make(error) ?? .other)
                listenerTask = nil
            }
        }
    }

    public func removeSnapshotListener() async {
        listenerTask?.cancel()
        await listenerTask?.value
        listenerTask = nil
        await cohabitantClient.removeSnapshotListener(cohabitantListenerKey)
    }

}

public extension EnvironmentValues {

    /// 家事グループメンバー
    @Entry var cohabitantMembers: CohabitantMemberList = .init(value: [], ownId: "")

}
