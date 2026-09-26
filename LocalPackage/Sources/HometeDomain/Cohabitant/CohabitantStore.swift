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
    /// 購読の世代。準備中に解除・破棄が走ったかどうかの判定に使う
    private var listenerGeneration = 0

    private let cohabitantListenerKey = "cohabitantListenerKey"

    // MARK: Dependencies

    private let cohabitantClient: CohabitantClient
    private let accountInfoClient: AccountInfoClient
    private let analyticsClient: AnalyticsClient

    public init(
        members: Set<CohabitantMember> = [],
        ownId: String = "",
        cohabitantClient: CohabitantClient = .previewValue,
        accountInfoClient: AccountInfoClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) {
        self.members = .init(value: members, ownId: ownId)
        self.cohabitantClient = cohabitantClient
        self.accountInfoClient = accountInfoClient
        self.analyticsClient = analyticsClient
    }

    public func addSnapshotListenerIfNeeded(_ cohabitantId: String) async {
        // すでに監視中の場合は何もしない
        if listenerTask != nil { return }

        listenerGeneration += 1
        let generation = listenerGeneration
        loadState = .loading
        let stream = await cohabitantClient.addSnapshotListener(
            cohabitantListenerKey,
            cohabitantId
        )

        // 購読の準備中に解除・サインアウトが走った場合、`listenerTask`が未設定のため解除は空振りする。
        // そのまま購読を張ると権限を失ったグループIDのまま残るので、ここで畳む
        guard generation == listenerGeneration else {
            await cohabitantClient.removeSnapshotListener(cohabitantListenerKey)
            return
        }

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
                    analyticsClient.setUserProperty(.cohabitantMemberCount(members.value.count))
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
        // 準備中の購読があれば、再開しても張られないよう世代を進める
        listenerGeneration += 1
        listenerTask?.cancel()
        await listenerTask?.value
        listenerTask = nil
        await cohabitantClient.removeSnapshotListener(cohabitantListenerKey)
    }

    /// サインアウト時に購読を止め、前のユーザーのグループ情報を破棄する
    /// - Note: このStoreはrootで生成されてサインアウトしても解放されないため、明示的に止めないと
    ///         無効になったグループIDのままFirestoreを購読し続ける
    public func clearOnSignedOut() async {
        await removeSnapshotListener()
        members = .init(value: [], ownId: "")
        loadState = .loading
    }

}

public extension EnvironmentValues {

    /// 家事グループメンバー
    @Entry var cohabitantMembers: CohabitantMemberList = .init(value: [], ownId: "")

}
