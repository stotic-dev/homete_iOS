//
//  TaskTracker.swift
//  LocalPackage
//

/// ViewModelが始めた非同期の処理を追跡する
///
/// CLI・行動テストは`waitUntilIdle()`で処理の完了を待つ。固定時間のsleepで待たないため。
@MainActor
public final class TaskTracker {

    private var tasks: [Int: Task<Void, Never>] = [:]
    private var nextID = 0

    public init() {}

    /// 終わっていない処理があるか
    public var hasPendingWork: Bool {
        !tasks.isEmpty
    }

    /// 処理を始める。終わったら追跡から外す
    func run(_ operation: @escaping @MainActor () async -> Void) {
        let id = nextID
        nextID += 1
        tasks[id] = Task {
            await operation()
            self.tasks[id] = nil
        }
    }

    /// 追跡中の処理がすべて終わるまで待つ。待っている間に始まった処理も待つ
    public func waitUntilIdle() async {
        while let task = tasks.values.first {
            await task.value
        }
    }

}
