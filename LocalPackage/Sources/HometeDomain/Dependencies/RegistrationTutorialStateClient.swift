//
//  RegistrationTutorialStateClient.swift
//  LocalPackage
//

/// グループ登録の直後に出すチュートリアルが、まだ見終わっていないかどうかを永続化するClient
/// - Note: 登録の直後にアプリを終了されても、次の起動でチュートリアルを出し直せるようにするために使う。
///         記録は端末単位とし、再インストール・機種変更では引き継がない
public struct RegistrationTutorialStateClient: Sendable {

    /// チュートリアルを出す必要が残っているかどうかを読み出す
    public let loadIsPending: @Sendable () async -> Bool
    /// チュートリアルを出す必要が残っているかどうかを記録する
    public let saveIsPending: @Sendable (Bool) async -> Void

    public init(
        loadIsPending: @Sendable @escaping () async -> Bool = { false },
        saveIsPending: @Sendable @escaping (Bool) async -> Void = { _ in }
    ) {
        self.loadIsPending = loadIsPending
        self.saveIsPending = saveIsPending
    }

}

public extension RegistrationTutorialStateClient {

    static let previewValue: RegistrationTutorialStateClient = .init()

}
