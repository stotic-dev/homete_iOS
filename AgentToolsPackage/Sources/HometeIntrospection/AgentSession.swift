//
//  AgentSession.swift
//  AgentToolsPackage
//

import HometeAppCore
import HometeDomain

/// CLI・行動テストが動かす画面のViewModelと、それが使うStore
///
/// iOSでは`AppTabView`がStoreを組み立て、各画面がViewModelを作る。ここでは同じViewModelを
/// fixtureの依存で組み立てる（`HometeScenarioSupport`の`Scenario`）。
@MainActor
public final class AgentSession {

    /// ダッシュボードの「今日の家事」
    public let today: TodayHouseworkViewModel
    public let houseworkListStore: HouseworkListStore
    /// ViewModelが始めた非同期の処理
    public let tasks: TaskTracker

    public init(today: TodayHouseworkViewModel, houseworkListStore: HouseworkListStore, tasks: TaskTracker) {
        self.today = today
        self.houseworkListStore = houseworkListStore
        self.tasks = tasks
    }

    /// ViewModelが始めた非同期の処理がすべて終わり、書き込んだ家事がStoreに届くまで待つ
    ///
    /// - Note: `HouseworkListStore`は書き込んだ家事を`HouseworkManager`（actor）の通知から受け取るので、
    ///         処理が終わった後にMainActorの順番を譲って、通知を受け取る処理を先に進める。
    ///         通知の経路にactorの移り先が増えて行動テストが不安定になったら、`yieldCountForStoreUpdates`を増やす
    public func settle() async {
        await tasks.waitUntilIdle()
        for _ in 0 ..< Self.yieldCountForStoreUpdates {
            await Task.yield()
        }
    }

}

private extension AgentSession {

    /// 書き込みの後、Storeに通知が届くまでにMainActorの順番を譲る回数
    static let yieldCountForStoreUpdates = 20

}
