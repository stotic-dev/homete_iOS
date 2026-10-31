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
    /// リアルタイムリスナーの期間（±N日）の起点
    private var listenerAnchorDate: Date = .now
    /// ワンショットフェッチ済みの期間。この範囲より過去は未取得のため、必要になった時点で追加取得する
    public private(set) var fetchedRange: ClosedRange<Date>?
    private var streamContinuationDic: [String: AsyncStream<Result<[HouseworkItem], DomainError>>.Continuation] = [:]
    private var observeTask: Task<Void, Never>?
    /// 進行中の追加フェッチ。同じ期間を重複して取得しないための待ち合わせに使う
    private var pendingFetchTask: Task<Int?, Never>?
    /// 監視の世代。actorの再入により、中断中の準備処理が後から状態を書き戻すのを防ぐために使う
    private var observeGeneration = 0
    /// 購読中（準備中を含む）の条件。初回フェッチかリスナーが失敗したら`nil`に戻し、次の呼び出しでやり直させる
    private var activeCondition: ObserveCondition?
    /// 張っているリアルタイムリスナーのID
    /// - Note: IDは世代ごとに変える。共通のIDで外すと、再開した古い世代が新しい世代のリスナーまで外してしまい、
    ///         `activeCondition`が残ったまま購読が止まって、張り直す機会もなくなるため
    private var listenerId: String?
    /// 家事ボードで選ばれている日。リアルタイムリスナーの期間（±N日）の外なら、その日だけを購読するリスナーを別に張る
    private var focusedDay: Date?
    /// 選ばれている日だけを購読するリスナーのID
    private var focusListenerId: String?
    private var focusTask: Task<Void, Never>?
    /// 選ばれている日のリスナーの世代。選び直しが続いたとき、古い呼び出しが後から張ったリスナーを残さないために使う
    private var focusGeneration = 0

    // MARK: Dependencies

    private let houseworkClient: HouseworkClient

    // MARK: constant

    private let houseworkObserveKey = "houseworkObserveKey"
    private let focusedDayObserveKey = "focusedDayHouseworkObserveKey"
    /// リアルタイムリスナーで購読する期間（今日の前後N日）
    ///
    /// 過去のありがとう漏れの一覧で7日前までの家事にありがとうを送るため、送った結果がすぐ反映されるよう7日前まで購読する。
    /// 未来側も、家事ボードで選べる7日後までそろえる
    private static let listenerOffset: Int = 7

    // MARK: initialize

    public init(houseworkClient: HouseworkClient) {
        self.houseworkClient = houseworkClient
    }

    /// テスト用：allItems を初期値で設定する
    /// - Parameter fetchedRange: 初回のフェッチを終えた状態から始める場合に渡す
    public init(houseworkClient: HouseworkClient, allItems: [HouseworkItem], fetchedRange: ClosedRange<Date>? = nil) {
        self.houseworkClient = houseworkClient
        self.allItems = allItems
        self.fetchedRange = fetchedRange
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
    ///         ただし家事ボードで選んでいる日だけは、`focus(on:calendar:)`で別に購読するため反映される。
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
        await removeFocusListener()
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

        // 4. 選ばれている日がリスナーの期間から外れていれば、その日だけのリスナーを張り直す
        await updateFocusListener(cohabitantId: cohabitantId, calendar: calendar)
    }

    /// 家事ボードで選んだ日の家事を、リアルタイムに受け取れるようにする
    ///
    /// 選んだ日がリアルタイムリスナーの期間（±N日）の外なら、その日だけを購読するリスナーを張る。
    /// ワンショットフェッチの期間より前の日でも、リスナーの初回の通知でその日の家事がそろう。
    /// - Note: 期間内の日を選び直したときは、張っていたリスナーを外す。リスナーは常に1日分だけにして、読み取りを増やさない
    public func focus(on date: Date, calendar: Calendar) async {
        let day = calendar.startOfDay(for: date)
        guard day != focusedDay else { return }
        focusedDay = day

        guard let cohabitantId = activeCondition?.cohabitantId else { return }
        await updateFocusListener(cohabitantId: cohabitantId, calendar: calendar)
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
        focusedDay = nil
        await removeFocusListener()
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
        guard await waitForPendingFetch() else { return }

        let targetDay = calendar.startOfDay(for: targetDate)
        guard let fetchedRange, targetDay < fetchedRange.lowerBound else { return }

        // 取得済み範囲と重複しないよう、その前日までを取得する
        let to = calendar.date(byAdding: .day, value: -1, to: fetchedRange.lowerBound) ?? fetchedRange.lowerBound
        _ = await runAppendTask(cohabitantId: cohabitantId, from: targetDay, to: to)
    }

    /// 取得済みの期間より前を、指定した月数ぶん追加でフェッチする
    ///
    /// プレミアムユーザーがホームのやり残している家事を末尾までスクロールした際に呼ぶ。
    /// 家事が全部でいつまで遡れるかは事前に分からないため、取得した件数を返して打ち切りの判断を呼び出し側に任せる。
    /// - Returns: 追加で取得した家事の件数。初回のフェッチを終えていない・失敗した・サインアウトなどが割り込んだ場合は`nil`
    public func fetchOlderPeriod(months: Int, cohabitantId: String, calendar: Calendar) async -> Int? {
        // 進行中の追加フェッチがあれば完了を待ち、その結果の期間より前を取得する
        guard await waitForPendingFetch(),
              let fetchedRange,
              let from = calendar.date(byAdding: .month, value: -months, to: fetchedRange.lowerBound) else {
            return nil
        }

        // 取得済み範囲と重複しないよう、その前日までを取得する
        let to = calendar.date(byAdding: .day, value: -1, to: fetchedRange.lowerBound) ?? fetchedRange.lowerBound
        return await runAppendTask(cohabitantId: cohabitantId, from: from, to: to)
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

    /// 進行中の追加フェッチがあれば完了を待つ
    /// - Returns: 待っている間に、再セットアップ・サインアウトが割り込まなかったか
    /// - Note: 待っている間にグループが変わると、`fetchedRange`は新しいグループのものになる。
    ///         呼び出し側が持つ古いグループIDのまま続けると、前のグループの家事を新しいグループの一覧に混ぜてしまうため、続けさせない
    func waitForPendingFetch() async -> Bool {
        let generation = observeGeneration
        if let pendingFetchTask {
            _ = await pendingFetchTask.value
        }
        return generation == observeGeneration
    }

    /// 追加フェッチを進行中のフェッチとして登録して実行する
    /// - Note: 同じフェッチを待っていた別の呼び出しが先に再開し、次のフェッチを登録していることがある。
    ///         それを消すと重複して取得してしまうため、自分が登録したフェッチのときだけ外す
    func runAppendTask(cohabitantId: String, from: Date, to: Date) async -> Int? {
        let task = Task {
            await self.appendItems(cohabitantId: cohabitantId, from: from, to: to)
        }
        pendingFetchTask = task
        let fetchedCount = await task.value
        if pendingFetchTask == task {
            pendingFetchTask = nil
        }
        return fetchedCount
    }

    /// 選ばれている日だけを購読するリスナーを、選ばれている日に合わせて張り直す
    func updateFocusListener(cohabitantId: String, calendar: Calendar) async {
        await removeFocusListener()
        let generation = focusGeneration
        let currentObserveGeneration = observeGeneration

        let listenerPeriod = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: listenerAnchorDate,
            offsetDays: Self.listenerOffset,
            calendar: calendar
        )
        guard let focusedDay, !listenerPeriod.contains(focusedDay) else { return }

        let newListenerId = "\(focusedDayObserveKey)-\(generation)"
        let stream = await houseworkClient.snapshotListener(newListenerId, cohabitantId, focusedDay, 0)
        // 張っている間に日付の選び直し・再セットアップ・サインアウトが割り込んだら、自分で張った分だけを外す
        guard generation == focusGeneration, currentObserveGeneration == observeGeneration else {
            await houseworkClient.removeListener(newListenerId)
            return
        }
        focusListenerId = newListenerId
        focusTask = Task {
            await listenFocusedDay(stream, generation: generation)
        }
    }

    /// 選ばれている日だけを購読するリスナーを外す
    func removeFocusListener() async {
        // 準備中の`updateFocusListener`が再開しても、リスナーを残さないよう先に世代を進める
        focusGeneration += 1
        focusTask?.cancel()
        focusTask = nil
        guard let focusListenerId else { return }
        self.focusListenerId = nil
        await houseworkClient.removeListener(focusListenerId)
    }

    /// 選ばれている日のリスナーの更新を allItems に upsert マージして通知する
    /// - Note: 失敗しても家事ボード全体を失敗の表示にはしない。その日の家事はワンショットフェッチの分が残っているため。
    ///         次に同じ日を選び直したときに張り直せるよう、選ばれている日を忘れる
    func listenFocusedDay(_ stream: AsyncThrowingStream<[HouseworkItem], Error>, generation: Int) async {
        do {
            for try await currentItems in stream {
                // 外した後に届いた通知で、別の日・別のグループの家事を書き戻さない
                guard generation == focusGeneration else { return }
                upsert(currentItems)
                notifyObservers()
            }
        } catch {
            guard generation == focusGeneration else { return }
            print("failed to listen focused day housework items: \(error)")
            focusedDay = nil
        }
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
    /// - Returns: 取得した家事の件数。失敗した・反映しなかった場合は`nil`
    func appendItems(cohabitantId: String, from: Date, to: Date) async -> Int? {
        let generation = observeGeneration
        let fetchedItems: [HouseworkItem]
        do {
            fetchedItems = try await houseworkClient.fetchItems(cohabitantId, from, to)
        } catch {
            print("failed to fetch additional housework items: \(error)")
            return nil
        }
        // 追加フェッチ中にサインアウト・再セットアップが走った場合は反映しない
        guard generation == observeGeneration,
              let currentRange = fetchedRange else { return nil }

        upsert(fetchedItems)
        fetchedRange = min(from, currentRange.lowerBound) ... currentRange.upperBound
        notifyObservers()
        return fetchedItems.count
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
