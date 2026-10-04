//
//  HouseworkManager.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/11.
//

import Foundation

public final actor HouseworkManager {

    // MARK: state

    public private(set) var allItems: [HouseworkItem] = []
    public private(set) var listenerAnchorDate: Date = .now
    /// ワンショットフェッチ済みの期間。この範囲より過去は未取得のため、必要になった時点で追加取得する
    public private(set) var fetchedRange: ClosedRange<Date>?
    private var streamContinuationDic: [String: AsyncStream<Result<[HouseworkItem], DomainError>>.Continuation] = [:]
    private var observeTask: Task<Void, Never>?
    /// 進行中の追加フェッチ。同じ期間を重複して取得しないための待ち合わせに使う
    private var pendingFetchTask: Task<Void, Never>?
    /// 監視の世代。actorの再入により、中断中の準備処理が後から状態を書き戻すのを防ぐために使う
    private var observeGeneration = 0
    /// 購読中（準備中を含む）の条件。初回フェッチかリスナーが失敗したら`nil`に戻し、次の呼び出しでやり直させる
    private var activeCondition: ObserveCondition?
    /// 張っているリアルタイムリスナーのID
    /// - Note: IDは世代ごとに変える。共通のIDで外すと、再開した古い世代が新しい世代のリスナーまで外してしまい、
    ///         `activeCondition`が残ったまま購読が止まって、張り直す機会もなくなるため
    private var listenerId: String?

    // MARK: Dependencies

    private let houseworkClient: HouseworkClient

    // MARK: constant

    private let houseworkObserveKey = "houseworkObserveKey"
    public static let listenerOffset: Int = 3

    // MARK: initialize

    public init(houseworkClient: HouseworkClient) {
        self.houseworkClient = houseworkClient
    }

    /// テスト用：allItems を初期値で設定する
    public init(houseworkClient: HouseworkClient, allItems: [HouseworkItem]) {
        self.houseworkClient = houseworkClient
        self.allItems = allItems
    }

    // MARK: public method

    /// allItems 変化を通知する AsyncStream を生成して返す
    ///
    /// - Note: Firestoreリスナーのエラーで購読が止まっても再購読（`setupObserver`の再呼び出し）で
    ///         復帰できるよう、失敗時もストリームは`finish`せず`Result.failure`を流すだけに留める。
    /// - Note: Storeは初期化時の`Task`から購読するため、`setupObserver`の初回フェッチ通知より後に
    ///         購読が届くことがある。取りこぼして画面が空のままにならないよう、初回フェッチ済みなら
    ///         その時点の`allItems`を購読直後に流す。
    public func createObserver(_ key: String) -> AsyncStream<Result<[HouseworkItem], DomainError>> {
        let (stream, continuation) = AsyncStream<Result<[HouseworkItem], DomainError>>.makeStream()
        streamContinuationDic.updateValue(continuation, forKey: key)
        if fetchedRange != nil {
            continuation.yield(.success(allItems))
        }
        return stream
    }

    /// 家事のワンショットフェッチとリアルタイムリスナーを準備する
    ///
    /// - Note: 画面の表示（タブの切り替えや戻る操作）のたびに呼ばれるが、ワンショットフェッチはプランに応じた
    ///         数ヶ月分の家事をサーバーから読むため、そのたびに読み取りが課金される。
    ///         同じグループ・同じ日・同じプランで購読中（準備中を含む）なら何もしない。
    ///         そのため、リスナーの期間（±N日）より前の家事を同居人が変えても、条件が変わるまでは反映されない。
    public func setupObserver(
        currentTime: Date,
        cohabitantId: String,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy
    ) async {
        let condition = ObserveCondition(
            cohabitantId: cohabitantId,
            day: calendar.startOfDay(for: currentTime),
            storagePolicy: storagePolicy
        )
        guard condition != activeCondition else { return }
        activeCondition = condition

        // このactorはawaitのたびに再入するため、以降の各ステップでは自分の世代が最新かを確認する。
        // 確認を省くと、サインアウト（`clearOnSignedOut`）や再セットアップが割り込んだあとに
        // このメソッドが再開して、権限を失ったグループのデータとリスナーを復活させてしまう
        observeGeneration += 1
        let generation = observeGeneration
        listenerAnchorDate = currentTime
        observeTask?.cancel()
        pendingFetchTask?.cancel()
        pendingFetchTask = nil
        await removeListener()
        guard generation == observeGeneration else { return }

        // 1. プランに応じた期間をワンショットフェッチして allItems を初期化
        let lowerBound = storagePolicy.initialFetchLowerBound(currentDate: currentTime, calendar: calendar)
        do {
            let fetchedItems = try await houseworkClient.fetchItems(cohabitantId, lowerBound, currentTime)
            guard generation == observeGeneration else { return }
            allItems = fetchedItems
            fetchedRange = lowerBound ... currentTime
            notifyObservers()
        } catch {
            guard generation == observeGeneration else { return }
            print("failed to fetch housework items: \(error)")
            activeCondition = nil
            notifyFailure(error)
        }

        // 2. ±N日のリアルタイムリスナー起動
        let newListenerId = "\(houseworkObserveKey)-\(generation)"
        let houseworkListStream = await houseworkClient.snapshotListener(
            newListenerId,
            cohabitantId,
            currentTime,
            Self.listenerOffset
        )
        guard generation == observeGeneration else {
            // 自分の世代で張ったリスナーだけを外す
            await houseworkClient.removeListener(newListenerId)
            return
        }
        listenerId = newListenerId

        // 3. 更新を allItems に upsert マージして通知
        observeTask = Task {
            await listen(houseworkListStream, generation: generation)
        }
    }

    /// サインアウト時に監視を止め、前のユーザーの家事データを破棄する
    /// - Note: このManagerは`AppDependencies`が保持していてサインアウトしても解放されないため、
    ///         明示的に止めないと無効になったグループIDのままFirestoreを購読し続ける
    public func clearOnSignedOut() async {
        // 準備中の`setupObserver`が再開しても状態を書き戻さないよう、先に世代を進める
        observeGeneration += 1
        activeCondition = nil
        observeTask?.cancel()
        observeTask = nil
        pendingFetchTask?.cancel()
        pendingFetchTask = nil
        await removeListener()
        allItems = []
        fetchedRange = nil
        notifyObservers()
    }

    /// 指定日まで遡って参照できるように、未取得の期間を追加でフェッチする
    ///
    /// プレミアムユーザーが貢献度画面で取得済み期間より過去へ遡った際に呼ぶ。
    /// すでに取得済みの期間内であれば何もしない。
    public func fetchIfNeeded(until targetDate: Date, cohabitantId: String, calendar: Calendar) async {
        // 進行中の追加フェッチがあれば完了を待つ。待っている間に対象期間が取得済みになるケースがある
        if let pendingFetchTask {
            await pendingFetchTask.value
        }

        let targetDay = calendar.startOfDay(for: targetDate)
        guard let fetchedRange, targetDay < fetchedRange.lowerBound else { return }

        // 取得済み範囲と重複しないよう、その前日までを取得する
        let to = calendar.date(byAdding: .day, value: -1, to: fetchedRange.lowerBound) ?? fetchedRange.lowerBound
        let task = Task {
            await self.appendItems(cohabitantId: cohabitantId, from: targetDay, to: to)
        }
        pendingFetchTask = task
        await task.value
        pendingFetchTask = nil
    }

}

// MARK: private

private extension HouseworkManager {

    /// 張っているリアルタイムリスナーを外す
    func removeListener() async {
        guard let listenerId else { return }
        // 外し終わるのを待つ間に再入されても、同じリスナーを二重に外さないよう先に手放す
        self.listenerId = nil
        await houseworkClient.removeListener(listenerId)
    }

    /// リアルタイムリスナーの更新を allItems に upsert マージして通知する
    func listen(_ stream: AsyncThrowingStream<[HouseworkItem], Error>, generation: Int) async {
        do {
            for try await currentItems in stream {
                upsert(currentItems)
                notifyObservers()
            }
        } catch {
            // 張り替えた後に古いリスナーのエラーが届いても、新しい購読の状態を失敗にしない
            guard generation == observeGeneration else { return }
            print("failed to listen housework items: \(error)")
            activeCondition = nil
            notifyFailure(error)
        }
    }

    /// 追加フェッチした期間を allItems と fetchedRange に反映する
    func appendItems(cohabitantId: String, from: Date, to: Date) async {
        let generation = observeGeneration
        let fetchedItems: [HouseworkItem]
        do {
            fetchedItems = try await houseworkClient.fetchItems(cohabitantId, from, to)
        } catch {
            print("failed to fetch additional housework items: \(error)")
            return
        }
        // 追加フェッチ中にサインアウト・再セットアップが走った場合は反映しない
        guard generation == observeGeneration,
              let currentRange = fetchedRange else { return }

        upsert(fetchedItems)
        fetchedRange = min(from, currentRange.lowerBound) ... currentRange.upperBound
        notifyObservers()
    }

    func upsert(_ updatedItems: [HouseworkItem]) {
        var itemsDict = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        for item in updatedItems {
            itemsDict[item.id] = item
        }
        allItems = Array(itemsDict.values)
    }

    func notifyObservers() {
        for (_, continuation) in streamContinuationDic {
            continuation.yield(.success(allItems))
        }
    }

    /// フェッチ・リスナーの失敗をオブザーバーに通知する
    ///
    /// - Note: ストリームを`finish`すると再購読後の成功通知が届かなくなるため、`yield`のみで伝える。
    func notifyFailure(_ error: Error) {
        let domainError = DomainError.make(error) ?? .other
        for (_, continuation) in streamContinuationDic {
            continuation.yield(.failure(domainError))
        }
    }

}

/// 家事の購読の条件。これが変わったときだけワンショットフェッチとリスナーをやり直す
private struct ObserveCondition: Equatable {

    let cohabitantId: String
    /// リスナーの対象期間（±N日）とフェッチ期間の起点になる日
    let day: Date
    /// フェッチ期間を決めるプラン
    let storagePolicy: HouseworkStoragePolicy

}
