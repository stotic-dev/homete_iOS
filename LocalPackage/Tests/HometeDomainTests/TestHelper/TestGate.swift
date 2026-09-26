//
//  TestGate.swift
//  LocalPackage
//

/// 非同期処理を任意の地点で止めて、テスト側から再開させるための一度きりのゲート
///
/// 「awaitで中断している最中に別の操作が割り込んだ」状況を、`Task.sleep`のような
/// 時間依存なしに決定的に再現するために使う。
final class TestGate: @unchecked Sendable {

    private let arrived: AsyncStream<Void>
    private let arrivedContinuation: AsyncStream<Void>.Continuation
    private let opened: AsyncStream<Void>
    private let openedContinuation: AsyncStream<Void>.Continuation

    init() {
        (arrived, arrivedContinuation) = AsyncStream<Void>.makeStream()
        (opened, openedContinuation) = AsyncStream<Void>.makeStream()
    }

    /// テスト対象側から呼ぶ。到達を知らせ、`open()`されるまで待つ
    func wait() async {
        arrivedContinuation.yield()
        for await _ in opened {
            break
        }
    }

    /// テスト側から呼ぶ。テスト対象が`wait()`に到達するまで待つ
    func waitUntilArrived() async {
        for await _ in arrived {
            break
        }
    }

    /// テスト側から呼ぶ。止まっている処理を再開させる
    func open() {
        openedContinuation.yield()
    }

}
