//
//  SnapshotListenerBridging.swift
//  LocalPackage
//

/// エラー発生時のUI表現をまだ持たないリスナー向けに、
/// `FirestoreService`が返す`AsyncThrowingStream`をログ出力のうえ通常終了する`AsyncStream`へ変換する。
///
/// - Note: リスナーの戻り値型を`AsyncThrowingStream`や`Result`に変えると、Xcode 26.4.1の
///         ランタイムでテストプロセスが不定のシグナルで落ちるため、既存の型のまま据え置いている。
func bridgingToNonThrowing<Output: Sendable>(
    _ throwingStream: AsyncThrowingStream<Output, Error>
) -> AsyncStream<Output> {
    AsyncStream { continuation in
        let task = Task {
            do {
                for try await value in throwingStream {
                    continuation.yield(value)
                }
            } catch {
                print("occurred error at addSnapshotListener(type: \(Output.self), error: \(error))")
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
