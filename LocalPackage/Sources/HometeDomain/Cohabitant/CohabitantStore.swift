//
//  CohabitantStore.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import Observation
import SwiftUI

/// 所属している同居人グループのメンバーを保持する
///
/// このStoreは`RootView`で1つだけ生成して、サインイン・グループ参加をまたいで使い回す。
/// インスタンスを画面側でも作ると、購読を張っているStoreとサインアウト時に後片付けするStoreが
/// 食い違い、権限を失ったグループの購読やメンバーが残る。
@MainActor
@Observable
public final class CohabitantStore {

    public private(set) var members: CohabitantMemberList
    /// スナップショットリスナーの購読状態
    public private(set) var loadState: ListenerLoadState = .loading
    private var listenerTask: Task<Void, Never>?
    /// 購読の世代。準備中に解除・破棄が走ったかどうかの判定に使う
    private var listenerGeneration = 0
    /// 購読しているグループのID。グループが切り替わったかどうかの判定に使う
    private var observingCohabitantId: String?

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

    /// 指定したグループの購読を開始する
    /// - Parameters:
    ///   - cohabitantId: 購読するグループのID
    ///   - ownId: 自分のユーザーID。メンバー一覧で自分を先頭に並べるために使う
    /// - Note: Storeを使い回すため、購読済みかどうかとグループの切り替わりはここで判断する。
    ///         別のグループへ切り替わった場合は、前のグループの購読とメンバーを捨ててから張り直す
    public func addSnapshotListenerIfNeeded(_ cohabitantId: String, ownId: String) async {
        // すでに同じグループを監視中の場合は何もしない
        if listenerTask != nil, observingCohabitantId == cohabitantId { return }

        // 別のグループへ切り替わった場合は、前のグループの購読とメンバーを捨ててから張り直す
        if let observingCohabitantId, observingCohabitantId != cohabitantId {
            await removeSnapshotListener()
            members = .init(value: [], ownId: ownId)
        } else if members.ownId != ownId {
            members.update(ownId: ownId)
        }
        observingCohabitantId = cohabitantId

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
        observingCohabitantId = nil
        listenerTask?.cancel()
        await listenerTask?.value
        listenerTask = nil
        await cohabitantClient.removeSnapshotListener(cohabitantListenerKey)
    }

    /// 購読を止め、保持しているグループ情報を破棄する
    /// - Note: このStoreはrootで生成されてサインアウト・グループ脱退でも解放されないため、明示的に
    ///         捨てないと権限を失ったグループIDのままFirestoreを購読し、前のメンバーを表示し続ける
    public func clear() async {
        await removeSnapshotListener()
        members = .init(value: [], ownId: "")
        loadState = .loading
    }

}

public extension EnvironmentValues {

    /// 家事グループメンバー
    @Entry var cohabitantMembers: CohabitantMemberList = .init(value: [], ownId: "")

}
