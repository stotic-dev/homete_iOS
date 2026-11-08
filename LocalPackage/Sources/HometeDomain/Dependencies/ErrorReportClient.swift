//
//  ErrorReportClient.swift
//  LocalPackage
//

/// アプリは落ちないが、原因を追いたいエラーを記録するClient
public struct ErrorReportClient: Sendable {

    /// 非致命のエラーとして記録する
    /// - Parameters:
    ///   - error: 記録するエラー
    ///   - context: エラーが起きた状況（操作の名前・対象のIDなど）。エラーと一緒に記録する
    public let record: @Sendable (_ error: any Error, _ context: [String: String]) -> Void

    public init(
        record: @Sendable @escaping (_ error: any Error, _ context: [String: String]) -> Void = { _, _ in }
    ) {
        self.record = record
    }

}

public extension ErrorReportClient {

    static let previewValue = ErrorReportClient()

}
